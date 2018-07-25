/*
 libhello.mm
 A Simple shared object implementation.
 */

#include <stdio.h>
#include <string.h>
#include "libhello.h"

// Set aside some memory as a buffer to store a string
char *buff = new char[4096];

// Add a name to the message to output
char *Msg(const char *name)
{
    // The message
    const char *message="Hello and welcome to the Cerberus shared library test! ";
    
    // Copy the message and concatenate the name passed to the buffer
    strcpy(buff, message);
    strcat(buff, name);
    
    // Return to buffered string back
    return buff;
}

// Free the memory allocated for the message buffer
void MemFree()
{
    delete buff;
}
