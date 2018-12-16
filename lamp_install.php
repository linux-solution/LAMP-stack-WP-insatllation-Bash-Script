<?php
$request = getallheaders();

$ssh_host = $request["ip"];
$ssh_auth_user = $request["uname"];
$ssh_auth_pass = $request["upass"];
$mysqlpass = $request["mysqlpass"];

echo $ssh_host;
echo $ssh_auth_user;
echo $ssh_auth_pass;
echo $mysqlpass;

$ssh_port = 22; 
    
if (!($connection = ssh2_connect($ssh_host, $ssh_port))) { 
    throw new Exception('Cannot connect to server'); 
} 

if (!ssh2_auth_password($connection, $ssh_auth_user, $ssh_auth_pass)) { 
    throw new Exception('Autentication rejected by server'); 
} 

// Send the script file to the remote machine
ssh2_scp_send($connection, '/var/www/run.sh', 'run.sh', 0777);

// Run the commands
$stream = ssh2_exec($connection, "echo ".$upass." | sudo -S touch test.log");
$stream = ssh2_exec($connection, "echo ".$upass." | sudo -S chmod 777 test.log");
$stream = ssh2_exec($connection, "echo ".$upass." | sudo -S ./run.sh MySQL ".$mysqlpass." 2>&1 | sudo tee test.log");

// Fetch the stream to see the progress of the script
$errorStream = ssh2_fetch_stream($stream, SSH2_STREAM_STDERR);
stream_set_blocking($errorStream, true);
stream_set_blocking($stream, true);

echo "Output: " . stream_get_contents($stream);
echo "Error: " . stream_get_contents($errorStream);

// Close the streams        
fclose($errorStream);
fclose($stream);

?>