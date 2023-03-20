<?php
// Get the data sent from VB6 application
$name = $_POST['name'];
$age = $_POST['age'];

// Set the path to the text file
$file_path = 'myfile.txt';

// Open the file in append mode
$file = fopen($file_path, 'a');

// Write the data to the file
fwrite($file, "$name,$age\n");

// Close the file
fclose($file);

// Send a response back to the VB6 application
echo "Data saved successfully";
?>
