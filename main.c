#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define SHARED_MEM_SIZE 1024  // Size of the shared memory region

int main() {
    int fd;
    char *shared_memory;

    // Open or create a shared memory object
    fd = shm_open("/my_shared_memory", O_CREAT | O_RDWR, S_IRUSR | S_IWUSR);
    if (fd == -1) {
        perror("shm_open");
        exit(EXIT_FAILURE);
    }

    // Set the size of the shared memory object
    if (ftruncate(fd, SHARED_MEM_SIZE) == -1) {
        perror("ftruncate");
        exit(EXIT_FAILURE);
    }

    // Map the shared memory object into the process's address space
    shared_memory = mmap(NULL, SHARED_MEM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (shared_memory == MAP_FAILED) {
        perror("mmap");
        exit(EXIT_FAILURE);
    }

    // Close the file descriptor; the mapping is still valid
    close(fd);

    // Write data into the shared memory
    strcpy(shared_memory, "Hello, shared memory!");

    printf("Data written to shared memory: %s\n", shared_memory);

    // Wait for user input before exiting
    printf("Press Enter to exit...");
    getchar();

    // Unmap the shared memory
    if (munmap(shared_memory, SHARED_MEM_SIZE) == -1) {
        perror("munmap");
        exit(EXIT_FAILURE);
    }

    // Unlink the shared memory object
    if (shm_unlink("/my_shared_memory") == -1) {
        perror("shm_unlink");
        exit(EXIT_FAILURE);
    }

    return 0;
}
