#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;

my $DEBUG = 0;

sub help{
    print <<END_of_help

Read Fortran definitions of compile-time variables from a template, fill in
appropriate values for the variables *_GITVERSION, *_GITBRANCH, *_COMPILE_TIME,
*_COMPILE_HOST where '*' is replaced by VAR_PREFIX, and write to output file.

E.g. with VAR_PREFIX=QDYN, the line

    character(len=error_l) :: QDYN_GITBRANCH    = 'UNKNOWN'

in the template might result in the line

    character(len=error_l) :: QDYN_GITBRANCH = "master"

in the output.

Usage: fill_version.pl [options] VAR_PREFIX

 Options:
   --help            This help message
   --in FILE         Template file from which to read. Default: VERSION.in
   --out FILE        File to which to write. Default: VERSION.fi

END_of_help
}

sub fill_version{
    my $var_prefix = shift;
    my $infile = shift;
    my $outfile = shift;
    my $sha;
    my $branch;
    my $hostname;
    my $compile_time;
    my $s;
    my $def;
    open(IN, $infile) or die ("Couldn't open $infile for reading\n");
    open(OUT, ">$outfile") or die ("Couldn't open $infile for writing\n");
    while (<IN>){
        if (/^(.*::\s*).*GITVERSION\s*=\s*(.*)$/){
            $def = $1;
            $sha = $2;
            $sha =~ s/^['"](.*)['"]$/$1/;
            if (open(GIT, "git log -n1 2>&1 |")){
                $s = <GIT>;
                close GIT;
                if (defined($s)) {
                    if ($s =~ /commit (.*)$/){
                        $sha = $1;
                    } else {
                        warn("Couldn't get sha: $s\n") if ($DEBUG);
                    }
                } else {
                    warn("No answer from git command\n") if ($DEBUG);
                }
            } else {
                warn("Could not open pipe to git command\n") if ($DEBUG);
            }
            print OUT "$def${var_prefix}_GITVERSION = \"$sha\"\n";
        } elsif (/^(.*::\s*).*GITBRANCH\s*=\s*(.*)$/){
            $def = $1;
            $branch = $2;
            $branch =~ s/^['"](.*)['"]$/$1/;
            if (open(GIT, "git status 2>&1 |")){
                $s = <GIT>;
                close GIT;
                if (defined($s)) {
                    if ($s =~ /# On branch (.*)$/){
                        $branch = $1;
                    } else {
                        warn("Couldn't get branch name: $s\n") if ($DEBUG);
                    }
                } else {
                    warn("No answer from git command\n") if ($DEBUG);
                }
            } else {
                warn("Could not open pipe to git command\n") if ($DEBUG);
            }
            print OUT "$def${var_prefix}_GITBRANCH = \"$branch\"\n";
        } elsif (/^(.*::\s*).*COMPILE_TIME\s*=\s*(.*)$/){
            $def = $1;
            $compile_time = localtime;
            print OUT "$def${var_prefix}_COMPILE_TIME = \"$compile_time\"\n";
        } elsif (/^(.*::\s*).*COMPILE_HOST\s*=\s*(.*)$/){
            $def = $1;
            $hostname = $2;
            $hostname =~ s/^['"](.*)['"]$/$1/;
            if (open(HOSTNAME, "hostname |")){
                $hostname = <HOSTNAME>;
                chomp $hostname;
                close HOSTNAME;
            } else {
                warn("Could not open pipe to hostname command\n") if ($DEBUG);
            }
            print OUT "$def${var_prefix}_COMPILE_HOST = \"$hostname\"\n";
        } else {
            print OUT;
        }
    }
    close OUT;
    close IN;
    print "Set compilation vars in $outfile\n";
    print "for $var_prefix rev. $sha ($branch)\n";
    print "on $hostname at $compile_time\n";
    return 0;
}


sub main{
    my $infile = 'VERSION.in';
    my $outfile = 'VERSION.fi';
    my $help = 0;
    GetOptions ( 'help|?' => \$help,
                 "out=s"  => \$outfile,
                 "in=s"   => \$infile) or help();
    if (@ARGV >= 1){
        my $var_prefix = $ARGV[0];
        return help() if $help;
        return fill_version($var_prefix, $infile, $outfile)
    } else {
        help();
        warn("ERROR: you need to provide VAR_PREFIX\n\n");
        return 1;
    }
}

main();
