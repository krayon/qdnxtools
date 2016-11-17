/* vim:set ts=4 sw=4 tw=80 et cindent ai si cino=(0,ml,\:0:
 * ( settings from: http://datapax.com.au/code_conventions/ )
 */

/**********************************************************************
    fork
    Copyright (C) 2016 Todd Harbour

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    version 2 ONLY, as published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program, in the file COPYING or COPYING.txt; if
    not, see http://www.gnu.org/licenses/ , or write to:
      The Free Software Foundation, Inc.,
      51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 **********************************************************************/

/*
 * BASED ON THE ORIGINAL CONCEPT BY
 * Storlek of irc://irc.freenode.net/#ArchLinux
 */

/* fork's an application, disconnected from the terminal
 * ("similar to 'nohup blah &>/dev/null </dev/null &' but
 * without the job").
 */

/*
 * v0.01 2011-07-30
 *     - Original by Storlek
 * v0.02 2016-10-27
 *     - (Near) complete rewrite
 *     - Made more portable (Solaris etc)
 * v0.02 2016-11-17
 *     - Added help
 */

#include <errno.h> /* errno */
#include <stdio.h> /* fprintf, perror */
#include <unistd.h> /* _exit, STDIN_FILENO, STDOUT_FILENO, STDERR_FILENO */
#include <signal.h> /* sigaction, SIGHUP, SIG_IGN */

#define APP_NAME                    "fork"
#define APP_VERSION                 "0.03"
#define APP_SUMMARY                 "Spawns a process that's COMPLETELY disconnected from the original parent process"
#define BIN_NAME                    "fork"
#define APP_AUTHOR                  "Todd Harbour"
#define APP_COPYRIGHT               "Copyright (C) 2016 "APP_AUTHOR
#define APP_URL                     "https://gitlab.com/krayon/qdnxtools/"

// TODO: i18n
#define _(STRING)                   STRING

static void help_version(void) {
    printf("%s v%s\n", (APP_NAME), (APP_VERSION));
    printf("%s\n", (APP_COPYRIGHT));
    printf("%s\n", (APP_URL));
}

static void help_usage(void) {
    printf("\
\n\
%s\n\
\n\
%s: %s -h|--help\n\
       %s -V|--version\n\
       %s [--] <program> [<args> [...]]\n\
\n\
-h|--help               - %s\n\
-V|--version            - %s %s %s\n\
\n\
[--]                    - %s\n\
<program>               - %s\n\
<args> [...]            - %s\n\
\n\
%s: %s youtube-dl https://www.youtube.com/watch?v=dQw4w9WgXcQ\n\
",
     _(APP_SUMMARY)

    ,_("Usage"),    BIN_NAME /* -h|--h[elp] */
    ,               BIN_NAME /* -V|--v[ersion] */
    ,               BIN_NAME /* -s|--s[elect] ... */

    ,_("Displays this help")
    ,_("Displays"), APP_NAME, _("version")
    ,_("Indicates all remaining parameters are for <program>")
    ,_("Program to run")
    ,_("Any arguments to pass to <program>")
    ,_("Example"),  BIN_NAME
    );
}

/* Not all systems implement daemon (Solaris, I'm looking at you) */
int daemon(int nochdir, int noclose) {
    /* 1. Fork process:
     *     * Unblocks grandparent process that may be waiting for parent to
     *       terminate;
     *     * Ensures child process is not a process group leader.
     */
    pid_t pid = fork();
    struct sigaction sa;

    /* fork failed */
    if (pid == -1) return -1;

    /* parent process */
    if (pid !=  0) _exit(0);

    /* 2. Create a new session:
     *     * Starts a new session with us as leader;
     *     * Starts a new process group, with us as process group leader.
     */
    if (setsid() == -1) return -1;

    /* 3. Ignore parent SIGHUP:
     *     When we fork again, the parent (who will be the session leader)
     *     will generate a SIGHUP when it dies. We therefore must ignore
     *     SIGHUP's.
     *
     *     NOTE: If this was a daemon that wanted to handle SIGHUP, we would
     *     need the handler to ignore the first SIGHUP as this would be the one
     *     from the parent.
     */
    sa.sa_handler = SIG_IGN;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGHUP, &sa, 0);

    /* 4. Fork again:
     *     * Ensures child process is not a session leader
     *
     *     We currently don't have a controlling terminal. In the event we open
     *     a terminal device, it becomes the controlling terminal automatically.
     *     Not being the session leader prevents this).
     */
    pid = fork();

    /* fork failed */
    if (pid == -1) return -1;

    /* parent process */
    if (pid !=  0) _exit(0);

    /* Change directory? */
    if (nochdir == 0) chdir("/");

    /* Close standard file descriptors? */
    if (noclose == 0) {
        close(STDIN_FILENO);
        close(STDOUT_FILENO);
        close(STDERR_FILENO);
    }

    return 0;
}

int main(int argc, char **argv) {
    int argoff = 1;

    if (argc < 2) {
        fprintf(stderr, "ERROR: No program specified\n");
        help_version();
        help_usage();
        _exit(1);
    }

    if (
           strcmp("--help", argv[argoff]) == 0
        || strcmp("-h",     argv[argoff]) == 0
    ) {
        help_version();
        help_usage();
        _exit(0);
    }

    if (
           strcmp("--version", argv[argoff]) == 0
        || strcmp("-V",        argv[argoff]) == 0
    ) {
        help_version();
        _exit(0);
    }

    if (strcmp("--", argv[argoff]) == 0) {
        ++argoff;
    }

    /* daemon(nochdir, noclose)
     *   If nochdir != 0, don't 'chdir /'
     *   If noclose != 0, don't redirect stdin/out/err to '/dev/null'
     */
    daemon(1, 0);

    /* Run the program (this exec's overwrites this process, which
     * therefore no longer exists.
     */
    execvp(argv[argoff], argv + argoff);

    /* If we get here the exec failed so we need to print out the
     * error info and return 255.
     */
    perror("execvp");
    _exit(255);
}
