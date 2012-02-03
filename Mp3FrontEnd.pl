#!/usr/bin/perl -w

use AtExit;
use IO::Dir;
use Curses;
use MP3::Info;


$Player = "/usr/bin/mpg123";
$basedir = "/home/egzoti4en/Desktop";
$currentdir = $basedir;
$Title = "Egzoti4en ";
$author = "Emiliyan Yankov";
$pid = 1;
$pid1 = 2;
$KillPlayer = "/usr/bin/killall";


#----------------------------------------------------------------------------
#Global Arrays

our @Directories ;
our @Files ;
our @FileDir ;
our @old_dir;
our @old_offset;
our @old_choosen_elemnt;
our @old_cursor;
our @tempFileDir;

#-----------------------------------------------------------------------------
#Song info scalars
$songPlayed =" ";
$time = 0.10;
$remseconds = 0;
$songseconds = 1;
$status_flag = 0;
$clear_flag = 0;
$tempdir =$currentdir;
$choosen_temp = 0;
#----------------------------------------------------------------------------
#Curses

initscr;
keypad(1);
clear;
noecho();
atexit(\&quit, "Bye Bye\n");

#-----------------------------------------------------------------------------
# Window Properties

$border_up= 0;
$border_down = 23;
$border_left = 0;
$border_right = 78;

#position of browser elements
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

sub player_window 
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
{#calls the player and starts the song
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
{#get files from currend directory
	
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
		foreach (@FileDir) 
		{#prints the files in @FileDir	
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
{#check the null of min and sec
	my $num = shift;
	if ($num <10) {return "0"."$num";}
    else {return "$num";}
}
sub status_line
{#draws the status line	
	my $mp3_info = get_mp3info("$songPlayed");	
		if ( defined $mp3_info ->{MM} && defined $mp3_info ->{SS} ) 
		{
			$songseconds = $mp3_info ->{SS} + $mp3_info->{MM}*60;
		}	
	$time = 2;
	while($time <= $songseconds)
	{#cycle till the time ends of the song		
			
		    
		    select(undef,undef,undef,0.05);
		    $time+=0.05;
		    refresh();
			#remaining time
	
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
			
			#draw the status line
				$x = ( (($border_right-3)-($border_left+3) -1) * $time);
				$x/=$songseconds;
				$x = int($x);
				foreach my $i (0..$x){$i%2 ? addstr($border_up+11, $i+$border_left+4, "\\" ) :
											 addstr($border_up+11, $i+$border_left+4, "/" ) ;}
				addstr($border_up+11, $border_left +3, "|");
				addstr($border_up+11, $border_right -3, "|");
				#curs_set();
	}		
	refresh();
	get_draw_files();
	$clear_flag =0;
	refresh();
	play_next_song();
}
sub quit 
{#execute upon quiting using AtEscape
	
	endwin();
	print "@_\n";
	exit(0);
}
sub get_draw_files 
{#get files and directories and draw the windows
	if($clear_flag == 0){clear();}
	else {clear_player()};
	get_files($currentdir);
	$maxoffset = scalar(@FileDir) - $elements_in_browser  ;
	browser_window();	
	player_window($songPlayed);
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
sub kill_player()
{#kills the player and the Status line
	$status_flag = 0;
	system($KillPlayer, "$Player");
	kill('TERM', $pid);
}
sub play_next_song()
{#plays next song from the temp choosen,dir,tempFileDir
	$choosen_temp=$choosen_temp - 1 ;
	if(defined $tempFileDir[abs($choosen_temp)])
	{
		kill('TERM', $pid1);
		$songPlayed  = $tempdir."/".$tempFileDir[abs($choosen_temp)] ;
		clear();
		$clear_flag = 1;
		get_draw_files();
		$status_flag = 1;
		#async(\&status_line)->detach;
		if($pid1 = fork()){status_line();}
		else{player($songPlayed);}
		
		nodelay(0);
	}
}

#---------------------------------------------------------------------------
#Star of execution of program
get_draw_files();

do 
{#Cycle waiting for Key to be inputed.Escape at F4 to stop
#-------------------------------------------------------------------------------
#Curser Variables
$maxoffset = scalar(@FileDir) - $elements_in_browser ;
move($cursor,1);

if ($pid!=0 and $key = getch() and $pid!=$pid1) 
{#checks the inputed key
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
				
				#info for playing next song
				$choosen_temp = $choosen_element;
				@tempFileDir = @FileDir;
				$tempdir = $currentdir;
				
				if($status_flag == 1){kill_player();}
				
				$songPlayed  = $currentdir."/".$FileDir[abs($choosen_element)] ;
				clear();
				$clear_flag = 1;
				get_draw_files();
				$status_flag = 1;
				if($pid = fork())
					{;}
				else 
					{
						$status_flag = 1;
						#async(\&status_line)->detach;
						if($pid1 =fork()){status_line();}
						else{player($songPlayed);}
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
	{
		if($status_flag == 1)
		{	
			kill_player();
		}
	}
	if ($key eq "268") 
	{
		if($status_flag ==1){kill_player();}
		last;
	}
}
} while(1>0);

quit();
endwin;


__END__
=head1 NAME

FrontEnd for MPG123 mp3 player

=head1 SYNOPSIS

Before executing the file you must declare the place of the MPG123 player 
and the place where your music is.By  default the values are 

=over 2

=item B<MPG123 :> '/usr/bin/mpg123' 

=item B<Musicfolder :> '/home/egzoti4en/Desktop'

=back

Here is a list of all the modules used:

=over 4

=item B<AtExit>

=item B<IO::Dir>

=item B<Curses>

=item B<MP3::Info>

=back

=head1 DESCRIPTION

Here is a detailed descrition of all the main variables and functions used

=head2 Variables

=head2 Player

Contains the location of the mp3 player used.

=head2 basedir

Contains the location of the starting Music folder

=head2 currentdir

Contains the information of the currentdir that is show in the browse window

=head2 Title

Contains the title show in the upper part of the FrontEnd

=head2 author

Contains information abount the first and last name of the author.This is 
variable is show in the lower part of the FrontEnd

=head2 pid and pid1

Contains information for the process that are started when a song is played

=head2 KillPlayer

Contains information for the plase of the kill all command

=head2 Global Arrays

=head3 Directories 

Contains all the current directories

=head3 Files

Contains all the current files

=head3 FileDir

Contains all the current directories + files

=head3 old_dir

Contains all the base directories

=head3 old_offset

Contains the old offsets

=head3 old_choosen_elemnt,old_cursor,tempFileDir

These are used for the playing of the next song

=head2 Functions

=head2 window

The window subroutine draws the browser window of the FronEnd and 
the SongInfo part. This subroutine uses the Curses module for drawing the
FrontEnd.The main variables used here are: 

=over 4

=item B<border_left>

Coordinates of the left part of the windows drawn.

=item B<border_right>

Coordinates of the right part of the windows drawn.

=item B<border_up>

Coordinates of the upper part of the windows drawn.

=item B<border_down>

Coordinates of the lower part of the windows drawn.

=back

=head2 get_files

This subroutine goes to the MusicFolder and reads of the files which are
*.mp3 and all the folders. It uses the module use IO::Dir.Here are the main
sorted arrays that it fills with information:
 
=over 3

=item B<Directories>

=item B<Files>

=item B<FileDir>

This array contains the Files and the Directories.It is used for easier access
to the Files and Folders.

=back

=head2 print_border

This subroutine gets as an imput a cordinates and a string. It shows on the
screen the String and if it is bigger than the coordinates it cuts it down.

=head2 browser_window

After the execution of get_files it is time to draw the Browser part of the
frontend player. It calls the window subroutine with the correct input.
Then the files and folders are drawn using the print_border subroutine.
Here the variable B<offset> is very important as this variable shows 
what part of the FileDir array to be shown on the screen. Also B<offset>
shows if there is a need of showing a '+' sign which means that there are 
more files/folders to be shown in the upper or lower part of the screen.

=head2 player_window

This subroutine gets the information from the song that is being played 
and shows it on the screen in the Song Info window.The main window is again 
drawn using the B<window> subroutine. For collecting the information of the
song Title,SongName,Album... the subroutine uses the MP3::Info module

=head2 get_draw_files

This subroutine combines the calling of the following functions.

=over 4

=item B<clear>

=item B<get_files>

=item B<browser_window>

=item B<player_window>

=back

=head2 addnul

This subroutine adds a 0 in the begining of a number if it is <10.
This used for the showing the time which is remaining and the time which 
has already elapsed

=head2 status_line

This subroutine draws the remaining and elapsed time and the status line.
It is executed in another process as this couting of time is made using 
a sleep activity and a cycle. The execution in another process is needed 
for the FrontEnd not to block during playing of the song. Again the info
is taken from the song using the MP3::Info module.

=head2 player

This subroutine takes as a parameter the song that needs to be played.It
executes the player that is defined by the global variable B<Player>.

=head2 clear_player

This subroutine is used instead of the function B<clear()> as when clear()
is used and the song is played the status line disappears.

=head2 play_next_song

This subroutine is used to play the next song after the current has finished.
The subroutine uses the following global variables to know which is the next
song 

=over 3

=item B<choosen_temp>

=item B<tempFileDir>

=item B<tempdir>

=back

=head2 kill_player

This subroutine is used to kill the player and to stop the status line
the count of the elapsed seconds.

=head2 quit

This subroutine describes what happens on exit. This is done using the 
module AtExit.

=head1 AUTHOR

Emiliyan Yankov, E<lt>eyankov.vn@gmail.comE<gt>


=cut
