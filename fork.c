/* fork.c
 *
 * v0.01 2011-07-30
 *     - Original by Storlek
 */

/* fork's an application, disconnected from the terminal
 * ("similar to 'nohup blah &>/dev/null </dev/null &' but
 * without the job" according to creator).
 *
 * Originally created by Storlek of freenode.net/#ArchLinux
 */
#include <stdio.h> /* fprintf, perror */
#include <stdlib.h> /* exit */
#include <unistd.h> /* daemon */

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: fork PROGRAM [args...]\n");
        exit(1);
    }

    /* daemon(nochdir, noclose)
     *   If nochdir != 0, don't 'chdir /'
     *   If noclose != 0, don't redirect stdin/out/err to '/dev/null'
     */
    daemon(1, 0);

    /* Run the program (this exec's overwrites this process, which
     * therefore no longer exists.
     */
    execvp(argv[1], argv + 1);

    /* If we get here the exec failed so we need to print out the
     * error info and return 255.
     */
    perror("execvp");
    exit(255);
}
