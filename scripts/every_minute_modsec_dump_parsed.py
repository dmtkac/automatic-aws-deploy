# This script parses ModSecurity raw logs and converts them into a format readable for the Fail2ban banning system

#!/usr/bin/env python3
import os
import re
import shutil
import logging

# Sets up logging to capture error information and write it to a log file
logging.basicConfig(filename='/home/ubuntu/every_minute_modsec_dump_parsed_debug.log', 
                    level=logging.ERROR,
                    format='%(asctime)s %(levelname)s:%(message)s')

# Function to parse ModSecurity logs from the specified file
def parse_modsec_logs(file_path, last_position):
    # Opens the log file and reads from the last read position to avoid reprocessing old logs
    with open(file_path, 'r') as file:
        file.seek(last_position)  # Moves to the last read position
        logs = file.read()  # Reads new logs
        new_position = file.tell()  # Gets the new position to track where we left off
        logging.debug(f"Last position: {last_position}, New position: {new_position}")
    
    # Splits the logs by transaction boundary markers using regex
    transactions = [t for t in re.split(r'---\w+---Z--', logs) if t.strip()]
    parsed_logs = []

    # Processes each transaction in the log
    for transaction in transactions:
        parts = re.split(r'---\w+---[A-Z]--', transaction)  # Further splits the transaction into parts
        log_data = {}
        # Extracts relevant information (IP, timestamp, HTTP method, status, etc.) using regex patterns
        for part in parts:
            if not part.strip():
                continue
            logging.debug(f"Processing part: {part}")
            date_match = re.search(r'(\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2} \+\d{4})', part)
            ip_match = re.search(r'\d+\.\d+\.\d+\.\d+', part)
            method_match = re.search(r'(GET|POST|PUT|DELETE|HEAD|OPTIONS|TRACE|CONNECT) (.*) HTTP', part)
            status_match = re.search(r'HTTP/1\.1\s+(\d+)', part)
            user_agent_match = re.search(r'User-Agent: (.*)', part)

            # If date and IP address are found, adds them to log_data
            if date_match and ip_match:
                log_data['timestamp'] = date_match.group(1)
                log_data['ip'] = ip_match.group(0)

            # Adds HTTP method and path to log_data
            if method_match:
                log_data['method'], log_data['path'] = method_match.groups()
            else:
                logging.error(f"Method/Path not found in part: {part}")

            # Adds HTTP status code to log_data
            if status_match:
                log_data['status'] = status_match.group(1)
            else:
                logging.error(f"Status entry not found: {status_match}")

            # Adds user agent information to log_data (if present)
            if user_agent_match:
                log_data['user_agent'] = user_agent_match.group(1).strip()

        # Ensures the required fields are present before formatting the log for output
        if all(key in log_data and log_data[key] != '-' for key in ['ip', 'timestamp', 'method', 'path', 'status']):
            # Formats the log into the required format for Fail2ban
            formatted_log = (f"{log_data['ip']} - - [{log_data['timestamp']}] "
                             f"\"{log_data['method']} {log_data['path']} HTTP/1.1\" "
                             f"{log_data['status']} \"{log_data.get('user_agent', '-')}\"")
            parsed_logs.append(formatted_log)
        else:
            logging.error(f"Incomplete log entry: {log_data}")

    return parsed_logs, new_position

# Function to write the parsed logs to the output file
def write_parsed_logs(parsed_logs, output_file_path):
    if not parsed_logs:
        return  # Returns early if there are no logs to write
    check_and_rotate_logs(output_file_path, 52428800)  # Checks if log rotation is needed (50MB limit)
    with open(output_file_path, 'a') as file:  # Appends new logs to the output file
        for log in parsed_logs:
            file.write(log + '\n')

# Function to check log size and rotate logs if they exceed the size limit
def check_and_rotate_logs(file_path, max_size):
    # If the file exists and exceeds the max size, rotates it
    if os.path.exists(file_path) and os.path.getsize(file_path) >= max_size:
        old_file_path = file_path.replace('.log', '_old.log')  # Creates the old log file name
        if os.path.exists(old_file_path):  # Removes the existing old log file
            os.remove(old_file_path)
        shutil.move(file_path, old_file_path)  # Moves the current log to the old file

# Function to get the last read position from a position tracking file
def get_last_read_position(pos_file, file_path):
    if os.path.exists(pos_file):
        # Reads the last known file position from the file
        with open(pos_file, 'r') as file:
            saved_position = int(file.read().strip())
    else:
        saved_position = 0  # Starts from the beginning if the file doesn't exist

    # Checks the current size of the log file
    current_size = os.path.getsize(file_path)
    # If the saved position is greater than the current file size (e.g., after log rotation), reset the pointer
    if saved_position > current_size:
        logging.info(f"Last read position {saved_position} is greater than file size {current_size}. Resetting pointer to 0.")
        return 0
    return saved_position

# Function to update the position tracking file with the new read position
def update_last_read_position(pos_file, position):
    with open(pos_file, 'w') as file:
        file.write(str(position))  # Writes the new position to the file

# Paths to the input (raw ModSecurity logs), output (parsed logs), and position file (to track the last read position)
input_file_path = '/home/ubuntu/modsec_audit.log'
output_file_path = '/home/ubuntu/modsec_audit_parsed.log'
position_file = '/home/ubuntu/last_read_position.txt'

# Gets the last read position from the position file (with a file size check)
last_position = get_last_read_position(position_file, input_file_path)

# Parses the logs from the last read position
parsed_logs, new_position = parse_modsec_logs(input_file_path, last_position)

# Writes the parsed logs to the output file
write_parsed_logs(parsed_logs, output_file_path)

# Updates the last read position so the script knows where to continue next time
update_last_read_position(position_file, new_position)