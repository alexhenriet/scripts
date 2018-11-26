#!/usr/bin/env php
<?php
$nick = $_SERVER['USER'];
$socket = @stream_socket_client("tcp://localhost:8765");
if (!$socket) die("Error: server is closed.\n");
stream_set_blocking($socket, 0);
stream_set_blocking(STDIN, 0);
while (true) {
  echo "<$nick> ";
  $read = [$socket, STDIN];
  $write = NULL;
  $except = NULL;
  if (!is_resource($socket)) return;
  $num_changed_streams = @stream_select($read, $write, $except, null);
  if (feof($socket)) return;
  if ($num_changed_streams  === 0) continue;
  if (false === $num_changed_streams) {
    die("Error: something wrong happened.\n");
  } elseif ($num_changed_streams > 0) {
    echo "\r";
    $data = fread($socket, 4096);
    if ($data !== '') echo '[' . date('H:i:s') . '] ' . $data;
    $data2 = fread(STDIN, 4096);
    if ($data2 !== '') fwrite($socket, trim("<$nick> " . $data2));
  }
}
