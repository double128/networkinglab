#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <pwd.h>
#include <grp.h>
#include <error.h>
#include <errno.h>
#include <syslog.h>
#include <string.h>
#include <limits.h>

#include <security/pam_appl.h>
#include <security/pam_modules.h>

#include <opengear/og_config.h>
#include <opengear/users.h>
#include <opengear/xmldb.h>
#include <opengear/pwgrp.h>
#include <opengear/roles.h>
#define PAM_DEBUG_ARG 1
#define CONFIG_PATH "/etc/config/config.xml"
#define USER_PASSWDFILE "/etc/config/passwd"
#define USER_PASSWDPERMS        (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)

#define USER_MINUID 1000
#define MINADMIN 12
#define DEFAULT_GROUP "netgrp"
#define USER_DEFAULTHOME "/etc/config/users/"

static char * pam_module_name = "pam_adduser";

static int checkUserRights(pam_handle_t *pamh);

static void _pam_log(int err, char *format, ...)
{
	va_list args;
	char buffer[1024];

	va_start(args, format);
	vsprintf(buffer, format, args);
	/* don't do openlog or closelog, but put our name in to be friendly */
	syslog(err, "%s: %s", pam_module_name, buffer);
	va_end(args);
}

/*
 * Adds a new local unix user
 *  - allocates a new uid, and entry in /etc/passwd
 *  - creates a new home directory with empty ~/.ssh
 *  - sets the default password to /bin/ursh
 */
static struct passwd *
addUser(struct pwgrp *pg, const char *user, gid_t gid)
{
	// Accumulate the bulk of the pasword entry
	struct passwd *pwd = pwgrp_new_passwd(pg);
	pwgrp_setstr(&pwd->pw_name, user);
	pwgrp_setstr(&pwd->pw_passwd,  "*");
	pwd->pw_gid = gid;
	pwgrp_setstr(&pwd->pw_gecos, "Network Authenticated User");
	pwgrp_setf(&pwd->pw_dir, "%s%s", USER_DEFAULTHOME, user);

	// grab a free uid
	// Walk passwd list by uid until we find an unused one >= USER_MINUID
	uid_t uid = USER_MINUID;
	while (pwgrp_getpwuid(pg, uid))
		uid++;

	_pam_log(LOG_INFO, "New user %s allocated uid %d", user, uid);
	pwd->pw_uid = uid;
	pwgrp_setstr(&pwd->pw_shell, (pwd->pw_uid == 0) ? "/bin/sh" : "/bin/ursh");

        // Create home dir base /etc/config/users
	if (mkdir(USER_DEFAULTHOME, 0755) == -1 && errno != EEXIST) {
		_pam_log(LOG_ALERT, "Failed to create dir: %s: %m",
			USER_DEFAULTHOME);
		return NULL;
	}

	// Create users home directory
	if (mkdir(pwd->pw_dir,
		S_IRUSR | S_IWUSR | S_IXUSR | S_IXOTH | S_IXGRP) != 0) {
		if (errno != EEXIST) {
			_pam_log(LOG_ALERT, "Failed to create dir: %s: %m", pwd->pw_dir);
			return NULL;
		}
	}

	// Owned by the correct user
	if (chown(pwd->pw_dir, pwd->pw_uid, 0)) {
		_pam_log(LOG_ALERT, "Failed to reassign directory ownership: %s: %m",
			pwd->pw_dir);
	}

	#ifdef HAVE_SSH
	// Create ~/.ssh for this user

	char sshdir[256];
	snprintf(sshdir, sizeof sshdir, "%s/.ssh", pwd->pw_dir);

	if (mkdir(sshdir, 0755) != 0 && errno != EEXIST) {
		_pam_log( LOG_ALERT,"Failed to create dir: %s: %m", sshdir);
		return NULL;
	}

	// SSH directory owned by the correct user
	if (chown(sshdir, pwd->pw_uid, 0)) {
		_pam_log(LOG_ALERT, "Failed to reassign directory ownership: %s: %s",
			sshdir, strerror(errno));
	}
	#endif

	return pwd;
}

/* A linked list of strings, used here to accumulating groups */
struct list {
	struct list *next;
	char str[1];
};
static int list_contains(struct list *l, const char *text);
static void list_insert(struct list **head, const char *text);
static void list_insert_unique(struct list **head, const char *text);
static void list_free(struct list **head);

/*
 * Shell policy
 *  initial    Default shell was /bin/sh
 *  2011-08-20 Use /bin/ursh, unless member of {users,admin} or uid=0
 *  2011-10-14 Use /bin/pmshell if member of {pmshell}
 *  2011-10-30 Use /bin/bash instead of /bin/sh
 *  2016-10    Use roles (admin, pmshell_user, shell_user) instead of groups
 */
#define USER_DEFAULTSHELL	"/bin/bash"
#define USER_RESTRICTSHELL	"/bin/ursh"

/* 
 * HEY READ THIS:
 * WE DECIDED THAT PMSHELL KINDA SUCKED SO WE'RE GOING TO USE 
 * OUR CUSTOM SCRIPT INSTEAD, SO NOW LOGINSHELL_MENU RUNS AS A 
 * FULL SHELL KTHX
 */

#define USER_PMSHELL_ONLY	"/etc/config/customscripts/loginshell_menu"

/* Set the user's shell according to their assigned roles */
static void
set_user_shell(struct passwd *pw, struct roles *roles)
{
	const char *shell;

	/* (Duplication of logic from the users configurator) */
	if (pw->pw_uid == 0)
		shell = USER_DEFAULTSHELL;
	else if (roles_has(roles, ROLE_PMSHELL_USER))
		shell = USER_PMSHELL_ONLY;
	else if (roles_has(roles, ROLE_SHELL_USER) || roles_has(roles, ROLE_ADMIN))
		shell = USER_DEFAULTSHELL;
	else
		shell = USER_RESTRICTSHELL;

	if (strcmp(pw->pw_shell, shell) != 0) {
		_pam_log(LOG_INFO, "user %s: set shell to %s",
			pw->pw_name, shell);
		pwgrp_setstr(&pw->pw_shell, shell);
	}
}

/* Ensure that the user is _only_ a member of the named groups.
 * This function only adjusts existing groups; it does not create new groups. */

/* THIS WAS MODIFIED BECAUSE WE DON'T WANT USERS BEING REMOVED FROM GROUPS PERIOD */
static void
set_user_groups(struct pwgrp *pg, const char *user, struct list *groups)
{
	unsigned i;

	for (i = 0; i < pg->ngroup; i++) {
		struct group *gr = pg->group[i];
		if (!gr)
			continue; /* (a group may have been deleted) */
		if (list_contains(groups, gr->gr_name)) {
			if (!group_has_mem(gr, user)) {
				_pam_log(LOG_INFO, "Adding user %s to group %s",
					user, gr->gr_name);
				group_add_mem(gr, user);
			}
		} else {
			if (group_has_mem(gr, user)) {
				group_add_mem(gr, user);
			}
		}
	}
}

// Decide if we need a new user, and if so, add them
PAM_EXTERN int
pam_sm_authenticate( pam_handle_t * pamh, int flags, int argc, const char * * argv )
{
	_pam_log( LOG_DEBUG, "Starting pam_sm_authenticate" );
	return checkUserRights(pamh);
}

/* Load all the roles for a group */
static void
fill_roles_from_group(xmldb_t *db, struct roles **roles_ptr, const char *group_name)
{
	roles_add_from_group(roles_ptr, group_name, xmldb_root(db));
}

/*
 * Reconstruct the user's group membership from:
 *  - their primary group
 *  - their config.users.userN.groups
 *  - the OG-GROUPS (passed through from radius/tacacs PAM modules)
 *
 * Note that /etc/groups is NOT used here (that's what we're building)
 */
static struct list *
rebuild_group_membership(struct pwgrp *pg, struct passwd *pwd,
			 struct xmldb *db, pam_handle_t *pamh)
{
	struct list *group_list;
	char **config_groups;
	size_t nconfig_groups = 0;
	struct group *gr;
	size_t i;

	/* Start with an empty list of groups */
	group_list = NULL;

	/* Add the user's primary group */
	gr = pwgrp_getgrgid(pg, pwd->pw_gid);
	if (gr)
		list_insert_unique(&group_list, gr->gr_name);

	/* Next, add group membership info from config.xml (config.groups) */
	config_groups = opengear_users_getlocalgroups(db, pwd->pw_name,
		&nconfig_groups);
	for (i = 0; i < nconfig_groups; i++) {
		list_insert_unique(&group_list, config_groups[i]);
		free(config_groups[i]);
	}
	free(config_groups);

	/* Add remote groups from another PAM module */
	if (xmldb_getbool(db, "auth", "useremotegroups")) {
		const char *og_groups = pam_getenv(pamh, "OG-GROUPS");
		if (og_groups) {
			char *cp = strdup(og_groups);
			char *sepstate = cp;
			char *group, *s;

			/*
			 * Convert the groups to lower case, replacing
			 * spaces with underscores.
			 */
			/* TODO delimiter should be changed to
			 * ':', not ',' */
			while ((group = strsep(&sepstate, ","))) {
				for (s = group; *s; s++) {
					if (*s == ' ')
						*s = '_';
					else
						*s = tolower(*s);
				}
				list_insert_unique(&group_list, group);
			}
			free(cp);
		}

		/*
		 * Previously there was a workaround here for a (hypothesized)
		 * misconfiguration of an RSA RADIUS server that was sometimes
		 * omitting sending group information. The workaround was to
		 * preserve existing groups when no groups had been sent.
		 * Unfortunately, that meant we can't distinguish between an
		 * AAA server actually revoking group membership.
		 */
	}
	return group_list;
}


/**
 * Ensure that the PAM user exists locally.
 *
 * Ensures that the user:
 *    - has an entry in /etc/passwd
 *    - has up-to-date membership in /etc/group
 *    - has a home and ~/.ssh directory
 *
 * @return
 *  PAM_IGNORE:       the username was empty or missing
 *  PAM_SERVICE_ERR:  unable to access critical local databases
 *  PAM_USER_UNKNOWN: could not create the user locally (conflict?)
 *  PAM_SUCCESS:      the user exists with uid<1000 (and was left unchanged); or
 *                    the passwd, group entries and ~/.ssh were updated/created
 */
static int
checkUserRights(pam_handle_t *pamh)
{
	struct group *netgrp;
	struct list *group_list = NULL, *l;
	struct pwgrp *pg = NULL;
	roles_t roles = NO_ROLES;
	const char *user;
	struct passwd *pwd;

	// This module has no effect without a valid username
	if (pam_get_user(pamh, &user, NULL) != PAM_SUCCESS)
		return PAM_IGNORE;
	if (!user || !strlen(user))
		return PAM_IGNORE;

	// Special case, never futz with existing system users
	pwd = getpwnam(user);
	if (pwd && pwd->pw_uid < USER_MINUID)
		return PAM_SUCCESS;

	// Open system databases potentially for edit
	pg = pwgrp_open();
	if (!pg) {
		return PAM_SERVICE_ERR;
	}

	// Find the group pointer for netgrp (may be NULL)
	netgrp = pwgrp_getgrnam(pg, DEFAULT_GROUP);

	// Open the config database for read
	xmldb_t *db = xmldb_create();
	if (!db) {
		_pam_log( LOG_ALERT, "Could not alloc config");
		pwgrp_abort(pg);
		return PAM_SERVICE_ERR;
	}
	if (xmldb_load(db, CONFIG_PATH) == -1) {
		_pam_log( LOG_ALERT, "Could not alloc config");
		xmldb_close(db);
		pwgrp_abort(pg);
		return PAM_SERVICE_ERR;
	}

	/* Create the user's password entry if they don't already exist. */
	pwd = pwgrp_getpwnam(pg, user);
	if (!pwd) {
		if (netgrp)
			pwd = addUser(pg, user, netgrp->gr_gid);
		if (!pwd) {
			/* We decided not to (or could not) create the user */
			pwgrp_abort(pg);
			return PAM_USER_UNKNOWN;
		}
	}

	/* Rebuild the user's group membership */
	group_list = rebuild_group_membership(pg, pwd, db, pamh);

	/*
	 * Roles currently affect group membership, and vice-versa.
	 * The following adds groups based on roles, and then
	 * recomputes the roles based on the new groups. Because
	 * roles only add new groups and groups only add new roles
	 * this will converge.
	 */
converge:
	/* Recompute fresh roles from current group membership list */
	roles_free(&roles);
	for (l = group_list; l; l = l->next)
		fill_roles_from_group(db, &roles, l->str);

	/* Admin role is special; we put the user in the admin group.
	 * Then we re-calculate the roles. */
	if (roles_has(roles, ROLE_ADMIN) &&
	    !list_contains(group_list, "admin"))
	{
		list_insert_unique(&group_list, "admin");
		goto converge;
	}
	if (roles_has(roles, ROLE_PMSHELL_USER) &&
	    !list_contains(group_list, "pmshell"))
	{
		list_insert_unique(&group_list, "pmshell");
		goto converge;
	}

	/* Admin is able to access tty devices directly */
	if (roles_has(roles, ROLE_ADMIN)) {
		list_insert_unique(&group_list, "serial");
	}


	set_user_groups(pg, user, group_list);
	set_user_shell(pwd, roles);

	/* Write out any changes to /etc/passwd and /etc/group */
	pwgrp_close(pg);

	roles_free(&roles);
	list_free(&group_list);
	xmldb_close(db);
	return PAM_SUCCESS;
}

PAM_EXTERN int
pam_sm_setcred( pam_handle_t * pamh, int flags, int argc, const char * * argv )
{
	_pam_log( LOG_DEBUG, "pam_sm_setcred" );
	return (PAM_SUCCESS);
}


PAM_EXTERN int
pam_sm_acct_mgmt( pam_handle_t * pamh, int flags, int argc, const char * * argv )
{
	_pam_log( LOG_DEBUG, "pam_sm_acct_mgmt" );
	return checkUserRights( pamh);
}

PAM_EXTERN int
pam_sm_open_session( pam_handle_t * pamh, int flags, int argc, const char * * argv )
{
	_pam_log( LOG_DEBUG, "pam_sm_open_session" );
	return (PAM_SUCCESS);
}


PAM_EXTERN int
pam_sm_close_session( pam_handle_t * pamh, int flags, int argc, const char * * argv )
{
	_pam_log( LOG_DEBUG, "pam_sm_close_session" );
	return (PAM_SUCCESS);
}

PAM_EXTERN int
pam_sm_chauthtok( pam_handle_t * pamh, int flags, int argc, const char * * argv )
{
	_pam_log( LOG_DEBUG, "pam_sm_chauthtok" );
	return (PAM_SUCCESS);
}

/*
 * Linked list of strings.
 * (Seems easier to work with than a vector of malloc'd pointers.)
 */

/* Tests if the string is a member of the list */
static int
list_contains(struct list *l, const char *text)
{
	for (; l; l = l->next)
		if (strcmp(text, l->str) == 0)
			return 1;
	return 0;
}

/* Inserts a string at front of list. The text is copied into the list element */
static void
list_insert(struct list **head, const char *text)
{
	/* Each element contains the whole string */
	struct list *l = malloc(sizeof *l + strlen(text));
	l->next = *head;
	strcpy(l->str, text);
	*head = l;
}

/* Inserts a string at front of list, unless it was already in the list */
static void
list_insert_unique(struct list **head, const char *text)
{
	if (!list_contains(*head, text))
		list_insert(head, text);
}

/* Frees all elements from the list */
static void
list_free(struct list **head)
{
	while (*head) {
		struct list *next = (*head)->next;
		free(*head);
		*head = next;
	}
}
