#!/usr/bin/perl -w

use AtExit;
use IO::Dir;
use Curses;
use MP3::Info;



$Player = "/usr/bin/mpg123";
$basedir = "/home/egzoti4en/Desktop";
$currentdir = $basedir;
#$old_dir =$basedir;
$Title = "Egzoti4en ";
$author = "Emiliyan Yankov";
$pid = 1;
$pid1 = 2;

#----------------------------------------------------------------------------
#Global Arrays

our @Directories ;
our @Files ;
our @FileDir ;
our @old_dir;
our @old_offset;
our @old_choosen_elemnt;
our @old_cursor;
$songPlayed =" ";
$time = 0.10;
$remseconds = 0;
$songseconds = 1;
$status_flag = 0;
#share($status_flag);
$clear_flag = 0;
#----------------------------------------------------------------------------
#Curses

initscr;
keypad(1);
clear;
noecho();
atexit(\&quit, "FrontEnd exited successfully\n");

#-----------------------------------------------------------------------------
# Window Properties

$border_up= 0;
$border_down = 23;
$border_left = 0;
$border_right = 78;


$startposition_up = $border_up + 15;
$startposition_left =$border_left + 2;

$endposition = $border_down - 4;
# Curosr variables
$cursor = $startposition_up + 1;
$choosen_element=0;
$offset = 0;
$elements_in_browser = 6;

#---------------------------------------------------------------------------

sub window 
{#draw the ouside borders of the window

	my $left = shift;
	my $up = shift;
	my $right = shift;
	my $down = shift;
	my $flag = shift;
	my $Title = shift;  #uper text
	my $Ending = shift;  #down text
	
	return 0 if ( ! defined $left|| ! defined $right || ! defined $down || ! defined $up );

	my $width = $right- $left + 1; #count of border elements from left till right
	my $height = $down - $up + 1;  #count of border elements from up till down

	return 0 if $width <= 0;
	return 0 if $height <= 0;

    if($flag ==1)
    {#Print Border Up and Down of main Player 
	    my $border = "*" x $width;
        addstr($up, $left, $border);
        addstr($down, $left, $border);
        addstr($startposition_up -2 ,$left, $border); #browse menu
    }
     
    if($flag == 2)
	{#Print Border Up,Down, Left and Right of Song Info 
		my $border = "#" x $width;
        addstr($up, $left, $border);
        addstr($down, $left, $border);
        foreach (2..$down)
        {
			addstr($_, $left, "#");
			addstr($_, $right, "#");
		}
		
	}   
	#Print Title in the upper part
	my $centertext = $width - length($Title);
	$centertext = int ( $centertext/2 );
	addstr($up, $centertext, $Title) if $Title && length($Title) <= $width;
	
	if($flag == 1)
	{#Print Ending in the lower part
	$centertext = $width - length($Ending);
	$centertext = int ( $centertext/2 );
	addstr($down, $centertext, $Ending) if $Ending && length($Ending) <= $width;
	}

	
	
	return 1;
}

sub playerwindow 
{#draw the song info window
	my $song=shift;
	my $left =$border_left+3;
	my $right = $border_right-3;
	my $up = $border_up+2;
	my $down = $border_down -15;
	if ( ! window($left,$up,$right,$down,2," Song Info ", " ")) {
	
			addstr(1,1, "error drawing player window\n");
			getch();
			exit;
		};
	if($song ne " ")
	{#print Song Info
		
		my $mp3_info = get_mp3tag("$song");	
		my @Song=(split('/',$song));
		@Song = split('-',pop(@Song));
		addstr($up + 1 , $left +2, "Artist:");
		if (defined $mp3_info->{ARTIST}) {addstr($up + 1 , $left + 9, $mp3_info->{ARTIST} );}
		else {addstr($up + 1 , $left + 9, $Song[0] );}
		addstr($up + 1 , $left +45, "Album:");
		if (defined $mp3_info->{ALBUM}) {addstr($up + 1 , $left + 52, $mp3_info->{ALBUM} );}
		addstr($up + 3 , $left +2, "Title:");
		if (defined $mp3_info->{TITLE}) {addstr($up + 3 , $left + 8, $mp3_info->{TITLE} );}
		else {my $title = pop(@Song);addstr($up + 3 , $left + 8, substr($title,0,length($title)-4));}
		$mp3_info = get_mp3info("$song");
		
		addstr($up + 3 , $left +45, "Bitrate:");
		if (defined $mp3_info->{BITRATE}) {addstr($up + 3 , $left + 53, "$mp3_info->{BITRATE} kbit/s" );}
		
		addstr($up + 5 , $left +2, "Frequency:");
		if (defined $mp3_info->{FREQUENCY}) {addstr($up + 5 , $left + 12,"$mp3_info->{FREQUENCY} kHz" );}
		
		addstr($up + 5 , $left +45, "Stereo:");
		if (defined $mp3_info->{STEREO}) {addstr($up + 5 , $left + 53, $mp3_info->{STEREO} ? "Yes" : "No"  );}
	}
		#Stop Button
		my $width = $border_right - $border_left;
		my $centertext = $width - length("Stop => Press Space");
		$centertext = int ( $centertext/2 );
		addstr($border_up+12, $centertext +20, "Stop => Press Space");
		$centertext = $width - length("Start => Press Enter");
		$centertext = int ( $centertext/2 );
		addstr($border_up+12, $centertext - 20, "Start => Press Enter");
		
	
}

sub player
{
	get_draw_files();
	
				close(STDOUT);
				close(STDERR);
				close(STDIN);

	my @args = ($Player, "-y", "-q", "-b 4196", shift);
	system(@args);
	#$status_flag =0;
	exit(0);
	
}
sub get_files
{ #get   files from currend directory
	
	undef @Directories;
	undef @Files;
	undef @FileDir;
	
	my $dir = shift;
	
	tie %d, IO::Dir,  $dir;
	
	foreach my $elem (keys %d) 
	{

			if ( $elem eq "." || $elem eq ".." ) { next; }
			if	( -f "$dir/$elem" ) {
				if ( $elem =~ /^(.+)\.mp3$/i) {push(@Files,"$elem");}}
			if	( -d "$dir/$elem" ) {push(@Directories,"$elem");}
		
	}
		@Directories = sort(@Directories);
		@Files = sort(@Files);
		@FileDir = (@Directories,@Files);
}

sub print_border 
{#cut elements if outside of border

	my $top = shift;
	my $left = shift;
	my $right = shift;
	my $elem = shift;

	return 0 if ! defined $top || ! defined $left || ! defined $right || ! defined $elem;

	addstr($top, $left, substr($elem,0,$right-$left) );

	return 1;
}


sub browser_window
{#draw the browser window
		

		if ( ! window($border_left,$border_up,$border_right,$border_down,1," $Title - FrontEndPlayer ", " * ".$author." * ")) {
	
			addstr(1,1, "error drawing window\n");
			getch();
			exit;
		};
		
		# show the current directory in the status
		addstr($startposition_up - 1, $startposition_left -1, "[". $currentdir ."]");

		# position in the browser
		$position = $startposition_up +1 ;
		
	
		#show + if more elements than height on the screen
		addstr($startposition_up, $startposition_left-1, "+") if $offset > 0 && $maxoffset >0;
		addstr($endposition+3, $startposition_left-1, "+")   if $offset <= scalar(@FileDir) -1 - $elements_in_browser && $maxoffset >0;

		$endoffpos = $elements_in_browser ;
		$offpos = $offset;
		foreach (@FileDir) {
			
			$offpos--;
			if  ($offpos>= 0){next;}
		    last if $endoffpos <=0;
			standout() if $cursor == $position;
		
			if ( $offset + $position - $startposition_up <= scalar(@Directories) ) 
			{#directory
				print_border($position, $startposition_left, $border_right-5, "<$_>");
			} 
			else 
			{#file
				print_border($position, $startposition_left, $border_right-5, "--$_");
			}

			standend() if $cursor == $position;

			$position++;
			$endoffpos--;
		}

	refresh();

}
sub addnul
{
	my $num = shift;
	if ($num <10) {return "0"."$num";}
    else {return "$num";}
}
	
sub status_line
{	
	
	my $mp3_info = get_mp3info("$songPlayed");	
			if ( defined $mp3_info ->{MM} && defined $mp3_info ->{SS} ) 
			{
				$songseconds = $mp3_info ->{SS} + $mp3_info->{MM}*60;
			}	
		$time = 2;
	while($time <= $songseconds && $status_flag == 1 )
	{		
			
		    
		    select(undef,undef,undef,0.05);
		    $time+=0.05;
		    refresh();
			#remaining time
			addstr(15,10,$status_flag);
				$remseconds = $songseconds - $time;
				my $x = ((($remseconds)/60)%60);
				my $min = int($x);
				$min = addnul($min);
				my $sec = int(($remseconds)%60);
				$sec = addnul($sec);
				addstr($border_up+10, $border_right-5, "$min:$sec");
			
			#played time
				$x = ((($time)/60)%60);
				$min = int($x);
				$min = addnul($min);
				$sec = int(($time)%60);
				$sec = addnul($sec);
				addstr($border_up+10, $border_left+1, "$min:$sec");

				$x = ( (($border_right-3)-($border_left+3) -1) * $time);
				$x/=$songseconds;
				$x = int($x);
				foreach my $i (0..$x){addstr($border_up+11, $i+$border_left+4, "#" );}
				addstr($border_up+11, $border_left +3, "|");
				addstr($border_up+11, $border_right -3, "|");
				#curs_set();
	}		
	
	refresh();
	get_draw_files();
	$clear_flag =0;
	refresh();
}



sub quit {#execute upon quiting using AtEscape
	
	endwin();
	print "@_\n";
	exit(0);
}

sub get_draw_files 
{#get files and directories and draw the browse window
	if($clear_flag == 0){clear();}
	else {clear_player()};
	get_files($currentdir);
	$maxoffset = scalar(@FileDir) - $elements_in_browser  ;
	browser_window();	
	playerwindow($songPlayed);
	move($cursor,1);
	
}
sub clear_player
{#clears everythin but the status line
	my $left =$border_left+3;
	my $right = $border_right-3;
	my $up = $border_up+2;
	my $down = $border_down -15;
	foreach my $i ($left..$right)
		{
			foreach my $j ($up..$down)
			{
				addstr($j,$i," ");
			}
		}
	$left = $border_left;
	$right =$border_right;
	$up = $startposition_up -2;	
	$down = $border_down;
	foreach my $i ($left..$right)
		{
			foreach my $j ($up..$down)
			{
				addstr($j,$i," ");
			}
		}

}
#---------------------------------------------------------------------------
#Star of execution of program
get_draw_files();



do 
{#Cycle waiting for Key to be inputed Escape at CTRL + C
#-------------------------------------------------------------------------------
#Curser Variables
$maxoffset = scalar(@FileDir) - $elements_in_browser ;
move($cursor,1);


if ($pid!=0 and $key = getch() and $pid!=$pid1) 
{ 
	get_draw_files();
	if ( $key eq "259" ) 
	{	
		if($choosen_element !=0)
		{
			$choosen_element++;
			if($maxoffset>0){$offset --;}
			else{$cursor--;}
			if(abs(scalar(@FileDir) -  $elements_in_browser) == $offset+1 && ($cursor != $startposition_up +1))
				{$cursor--;$offset++;}
			get_draw_files();
		}				
	}
	if ( $key eq "258" ) 
	{	
		
		if($cursor != $endposition +2 && abs($choosen_element)<scalar(@FileDir) -1)
		{
		$choosen_element--;
		if($maxoffset>0){$offset++;}
		else {$cursor++;}
		if(abs(scalar(@FileDir) -  $elements_in_browser) < $offset){$cursor++;$offset--;}
		get_draw_files();	
		}
	}
	if ($key eq "\n" || $key eq "261")
	{
		if(abs($choosen_element) <= scalar(@Directories) -1 )
		{
		
			push(@old_dir,$currentdir);
			push(@old_offset,$offset);
			push(@old_choosen_elemnt,$choosen_element);
			push(@old_cursor,$cursor);
			$currentdir = $currentdir."/".$Directories[abs($choosen_element)];
			$offset =0 ;
			$choosen_element =0;
			$cursor = $startposition_up +1;
			get_draw_files();	
		}
		else
		{
			if (defined $FileDir[$choosen_element])
			{
				$songPlayed  = $currentdir."/".$FileDir[abs($choosen_element)] ;
				
				$clear_flag = 1;
				get_draw_files();
				
				if($pid = fork())
				{;}
				else 
				{$status_flag = 1;
				#async(\&status_line)->detach;
				if($pid1 =fork())
				{status_line();}
				else{
				player($songPlayed);}
				}
				nodelay(0);
			}
		}
	
	}
	if ($key eq "263" || $key eq "260")
	{
			if($currentdir ne $basedir)
			{
			$currentdir=pop(@old_dir);
			$offset=pop(@old_offset);
			$choosen_element=pop(@old_choosen_elemnt);
			$cursor=pop(@old_cursor);
			get_draw_files();		
			}
	}
	if ($key eq ' ')
	{$status_flag =0;
	addstr(16,10,$status_flag);}
	if ($key eq ERR){exit(0);}
}

} while(1>0);

endwin;
