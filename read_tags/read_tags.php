<?php

$input_file = 'genflt20151120c.out';
$handle = fopen($input_file, "r");
if ($handle) {

    $counter = 0;
    $content = array();
    $field = '';


    $arr_tags = array(); // keep track of all the tags use here

    while (($line = fgets($handle)) !== false) {
        // process the line read.
        if (preg_match('/^RA BEGIN_OF_RECORD$/', $line)) {
            //if ( isset($content['CONTENTS']) )  {
            if ( $counter>0 ) {
                // print "ID:" . $content['ID'] . "\n";
                // print "CONTENTS:" . $content['CONTENTS'] . "\n";

                $arr_tags = get_tags($arr_tags, $content['CONTENTS']);
            }

            $content = array();
            $counter++;

        } elseif (preg_match('/^E\s+(\w+)$/', $line, $matches)) {
            $field = $matches[1];
            // $content->$field .= $line;

        } elseif (preg_match('/^D\s+(.*)$/', $line, $matches)) {
            $value = $matches[1];
            $content[$field] .= $value . "\n";

        } else {
            //print ">>>ditto: $line";
        }
        
        
    }

    $arr_tags = get_tags($arr_tags, $content['CONTENTS']);

    fclose($handle);

    print "counter=$counter\n";

    show_tags($arr_tags);

} else {
    // error opening the file.
} 

function get_tags($arr_tags, $instr) {

    $tag_name = '';
    $tag = 0;
    $strlen = strlen( $instr );
    for( $i = 0; $i <= $strlen; $i++ ) {
         $ch = substr( $instr, $i, 1 );

         if (preg_match('/[\[\]\<\>]/', $ch)) {
             $tag = !$tag;
             $tag_name .= $ch;

             if (!$tag && $tag_name!='') {
                 //print "TAG: $tag_name\n";
                 $arr_tags[$tag_name]++;
                 $tag_name = '';
             }

         } else {

             if ($tag) {
                 $tag_name .= $ch;
             }

         }

    }

    return $arr_tags;

}

function show_tags($tags) {
    foreach ($tags as $tag=>$value) {
       print "Tag: $tag ($value)\n";
    }
}


?>
