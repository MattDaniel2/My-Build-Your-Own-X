#####################################################
# Concurrent Server with SIGCHLD event handler      #
#####################################################
import errno
import os
import signal
import socket
import time

SERVER_ADDRESS = (HOST, PORT) = '', 8888
REQUEST_QUEUE_SIZE = 5

def grim_reaper(signum, frame):
    while True:
        try:
            pid, status = os.waitpid(
                -1,        #Wait for any child process
                os.WNOHANG #Do not block and return EWOULDBLOCK error
            )
        except OSError:
            return
        if pid == 0: # no more zombies
            return

def handle_request(client_connection):
    request = client_connection.recv(1024)
    print(
        'Child PID: {pid}. Parent PID {ppid}'.format(
            pid = os.getpid(),
            ppid = os.getppid(),
        )
    )
    print(request.decode())
    http_response = b"""\
        HTTP/1.1 200 OK

        Hello, World!
        """
    client_connection.sendall(http_response)

def serve_forever():
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(SERVER_ADDRESS)
    listen_socket.listen(REQUEST_QUEUE_SIZE)
    print('Serving HTTP on port {port}...'.format(port=PORT))
    print('Parent PID (PPID): {pid}\n'.format(pid=os.getpid()))

    signal.signal(signal.SIGCHLD, grim_reaper)

    while True:
        try:
            client_connection, client_address = listen_socket.accept()
        except IOError as e:
            code, msg = e.args
            #restart accept if it was interrupted
            if code == errno.EINTR:
                continue
            else:
                raise
        pid = os.fork()
        if pid == 0: # Child process
            #Close child copy of listen_socket fd, 
            #child does not care about listening to new
            #requests, only serving existing clients
            listen_socket.close() 
            handle_request(client_connection)
            client_connection.close()
            os._exit(0) #child process exits here
        else: #parent
            #Close parent copy and loop over, parent does not
            #care about servicing client connections, only listening
            #and passing off new client connections to child processes
            #Note that the client connection is not lost as
            #When parent closes, there is still a fd reference
            #to the client socket from the child process
            #client_connection.close() 
            client_connection.close()

if __name__ == '__main__':
    serve_forever()