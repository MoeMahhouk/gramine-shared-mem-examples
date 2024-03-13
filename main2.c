#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define FILE_PATH "shared_memory_file.txt"
#define FILE_SIZE 1024  // Size of the file

int main() {
    int fd;
    char *shared_memory;

    // Open or create a file
    fd = open(FILE_PATH, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR);
    if (fd == -1) {
        perror("open");
        exit(EXIT_FAILURE);
    }

    // Set the size of the file
    if (ftruncate(fd, FILE_SIZE) == -1) {
        perror("ftruncate");
        exit(EXIT_FAILURE);
    }

    // Map the file into the process's address space
    shared_memory = mmap(NULL, FILE_SIZE, PROT_READ , MAP_SHARED, fd, 0);
    if (shared_memory == MAP_FAILED) {
        perror("mmap");
        exit(EXIT_FAILURE);
    }

    // Close the file descriptor; the mapping is still valid
    close(fd);

    // Write data into the shared memory
    //strcpy(shared_memory, "Hello, shared memory!");

    printf("Data written to shared memory: %s\n", shared_memory);

    // Wait for user input before exiting
    printf("Press Enter to exit...");
    getchar();

    // Unmap the shared memory
    if (munmap(shared_memory, FILE_SIZE) == -1) {
        perror("munmap");
        exit(EXIT_FAILURE);
    }

    return 0;
}
