#include "repl.h"

/*
The main file of our SQLite database implementation
Main function will first handle the REPL loop, it is an
infinite loop that gives a prompt, takes input and 
processes that user input
*/
int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("Must supply a database filename.\n");
        exit(EXIT_FAILURE);
    }
    char* filename = argv[1];
    Table* table = db_open(filename);
    InputBuffer* input_buffer = new_input_buffer();
    while (true) {
        //print the static prompt on startup and then get user input
        print_prompt();
        read_input(input_buffer);

       if (input_buffer->buffer[0] == '.') {
           switch (do_meta_command(input_buffer, table)) {
            case (META_COMMAND_SUCCESS):
                continue;
            case (META_COMMAND_UNRECOGNIZED_COMMAND):
                printf("Unrecognized command '%s'\n", input_buffer->buffer);
                continue;
           }
       }
       Statement statement;
       switch (prepare_statement(input_buffer, &statement)) {
        case (PREPARE_SUCCESS):
            break;
        case (PREPARE_STRING_TOO_LONG):
            printf("Error: Strings are too long.\n");
            continue;
        case (PREPARE_NEGATIVE_ID):
            printf("Error: ID cannot be negative.\n");
            continue;
        case (PREPARE_SYNTAX_ERROR):
            printf("Syntax error. Could not parse statement.\n");
            continue;
        case (PREPARE_UNRECOGNIZED_STATEMENT):
            printf("Unrecognized keyword at start of '%s'.\n", input_buffer->buffer);
            continue;
       }
       
       switch (execute_statement(&statement, table)){
       case EXECUTE_SUCCESS:
           printf("Executed.\n");
           break;
       
       case EXECUTE_TABLE_FULL:
           printf("Error: Table Full.\n");
           break;
       }
    }
}