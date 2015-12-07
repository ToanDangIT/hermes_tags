#!/bin/perl
# 11/27/2015: sending articles between dn and inq via nrexport

use File::Basename ;
use File::Copy ;
use Env qw(HERMES HEDATA);
use Data::Dumper;

# begin main

my $arg ;

# first argument is the input file. second can be ignored
my $inFile = shift ;

if ($inFile eq '') {
    print "\n\nUsage: $0 <INFILE>\n\n";
    exit;
}

my ($name, $path, $ext ) = fileparse($inFile, "\.");

my $out_dir = "$HEDATA/import/from_hermes/for_dailynews" ;
my $out_dir = "/Users/tdang/www/hermes" ;
my $out_file = "${out_dir}/${name}" ;
my $hermimport_dir = "dnherm0:/dnherm0/hedata/import/processing/header/";

open ( IN, $inFile) or die "Could not open input file $inFile." ;

# read the entire file into an array
my @read_all = <IN>;

# cat the entire file array into a long string
my $long_string = join('', @read_all);


# Create Header File for hermimport
my $hdr_file = create_header($long_string, $out_dir);

# Create Text File for hermimport
my $txt_file = create_text($long_string, $out_dir);

my %dest_info = (
   'hdr_file' => $hdr_file,
   'txt_file' => $txt_file,
   'destination' => $hermimport_dir
);

# send_2_remote_hermes(%dest_info);

close IN;

# unlink $inFile || print "Scipt could not delete $inFile\n" ;


# end main

####################### ####################### #######################
sub create_header {
    my $i_string = shift;
    my $out_dir = shift;

    # print "INPUT STRING: $i_string\n";

    # INQ Regional-Copy-In # INQ Features-Copy-In # INQ Business-Copy-In # INQ Sports-Copy-In
    # DN News stories # DN Sports stories

    my ($name) = $i_string =~ m/(\@name\:.*)/ig;
    my ($type) = $i_string =~ m/(\@type\:.*)/ig;
    my ($date) = $i_string =~ m/(\@date\:.*)/ig;
    my ($subject) = $i_string =~ m/(\@subject\:.*)/ig;

    my ($slug) = $name =~ m/\@name\:\s+"?(\w+)"?/; 
    my ($dd,$mm,$yyyy) = $date =~ m/\@date\:\s+"?(\w+)\.(\w+)\.(\w+)"?/; 
    my ($level) = $i_string =~ m/\@level\:\s?"?(.*)"?/ig;

    if (index($level, 'INQ/SPORTS')>=0) {
        $dest_level = 'DN/SPORTS';
    } elsif (index($level, 'SYSTEMS')>=0) {
        $dest_level = 'SYSTEMS';
    } elsif (index($level, 'INQ/')>=0) {
        $dest_level = 'DN/NEWS';
    } elsif (index($level, 'DN/')>=0) {
        $dest_level = 'INQ/REGIONAL/COPY/IN';
    } else {
        $dest_level = 'DN/NEWS';
    }


    my $header_file = "$out_dir/$slug.hdr";

    # print "Dumper: $header_file\n";
    open ( OUT, ">$header_file") or die "Could not open output header file $header_file for writing." ;
    print OUT "$name\n";
    print OUT "$type\n";
    print OUT "\@date: $yyyy$mm$dd\n";
    # print OUT "$date\n";
    # print OUT "\@level: \"DN/TO_SAXO/STORIES\"\n";
    print OUT "\@level: \"$dest_level\"\n";
    print OUT "$subject\n";
    close OUT;


    return $header_file;
}

####################### ####################### #######################
sub create_text {
    my $i_string = shift;
    my $out_dir = shift;

    # print "INPUT STRING: $i_string\n";

    my ($name) = $i_string =~ m/(\@name\:.*)/ig;
    my ($type) = $i_string =~ m/(\@type\:.*)/ig;
    my ($date) = $i_string =~ m/(\@date\:.*)/ig;
    my ($level) = $i_string =~ m/(\@level\:.*)/ig;
    my ($body_text) = $i_string =~ m/\@TEXT\:\s+(.*)$/s;

    my $body_text = translate_tags($body_text);

    my ($slug) = $name =~ m/\@name\:\s+"?(\w+)"?/; 

    my $text_file = "$out_dir/$slug.txt";

    # print "Dumper: $text_file\n";
    open ( OUT, ">$text_file") or die "Could not open output text file $text_file for writing." ;
    # print "TEXT:\n$body_text\n";
    print OUT "$body_text\n";
    close OUT;


    return $text_file;
}

####################### ####################### #######################
sub translate_tags {
    $body = shift;

    # print $body;

# [WEBHEAD]<NO1>HEAD:This is a headline<NO>[/WEBHEAD]<NO1>WEBTAG: MyWebTag1, MyWebTag2
# <NO>[SUBHED_1]This is my SUBHED?1
# [/SUBHED_1][SUBHED_2]This is my SUBHED?2[/SUBHED_2]
# This is a test file for [BOLD]NRExport[/BOLD] between two [ITALIC]NEWSROOMS[/ITALIC].
# [ONLINE_SHIRT]<LG1,6,3,0,0,PHILLYCOM,9,0,31,31,0>
# <DC@1,1,1,0,0,0.6,-26.4,0,36,0,0><HS0.1><EL-45>- Toan
# [SIGNATURE]<QM>My Signature Here[/SIGNATURE]



    my %tags = (
        'WEBHEAD' => 'webhed',
        'NO1' => 'NO1',
        'SUBHED_1' => 'subhed1',
        'SUBHED_2' => 'subhed2',
        'ONLINE_SHIRT' => 'offline_skirt',
        'WHAT' => 'WHO',
        'SIGNATURE' => 'TEASER',
        '<HS0.1>' => '[not sure]',
        '<EL-45>' => '[not sure]',
        '<DC.*?>' => '', # clear this tag
        '<LG.*?>' => '', # clear this tag
    );

    foreach my $tag (keys %tags) {
        my $to_tag = $tags{$tag};
        # print "from=$tag -> to=$to_tag\n";
        $body =~ s/$tag/$to_tag/ge;
    }

    print $body;

    return $body;

} # end translate_tags


####################### ####################### #######################
sub send_2_remote_hermes {
    my $dest_info = shift;

    my $hdr_file = $dest_info{'hdr_file'};
    my $txt_file = $dest_info{'txt_file'};
    my $hermimport_dir = $dest_info{'destination'};

    # Remote copy to Hermimport folder
    `rcp "$hdr_file" "$hermimport_dir"`;
    `rcp "$txt_file" "$hermimport_dir"`;
}

