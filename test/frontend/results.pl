#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp qw(tempdir);

BEGIN {
    use_ok('allosmod');
    use_ok('saliweb::frontend');
}

my $t = new saliweb::Test('allosmod');

# Check results page

# Test allow_file_download
{
    my $self = $t->make_frontend();
    is($self->allow_file_download('bad.log'), '',
       "allow_file_download bad file");

    is($self->allow_file_download('output.zip'), 1,
       "                    good file 1");
    is($self->allow_file_download('failure.log'), 1,
       "                    good file 2");
}

# Check display_ok_job
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $ret = $frontend->display_ok_job($frontend->{CGI}, $job);
    like($ret, '/Job.*testjob.*has completed.*output\.zip.*' .
               'Download output zip file/ms', 'display_ok_job');
}

# Check display_failed_job (no output.zip)
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    my $ret = $frontend->display_failed_job($frontend->{CGI}, $job);
    like($ret, '/AllosMod was unable to complete your request.*' .
               'some common input errors.*' .
               'you can.*failure\.log.*download the log file.*' .
               'contact us/ms',
         'display_failed_job');
    chdir("/");
}

# Check display_failed_job (with output.zip)
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(open(FH, "> output.zip"), "Open output.zip");
    ok(close(FH), "Close output.zip");
    my $ret = $frontend->display_failed_job($frontend->{CGI}, $job);
    like($ret, '/AllosMod was unable to complete your request.*' .
               'some common input errors.*' .
               'you can.*failure\.log.*download the log file.*' .
               'output\.zip.*partial output zip file.*contact us/ms',
         'display_failed_job');
    chdir("/");
}

# Check get_results_page
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(open(FH, "> output.zip"), "Open output.zip");
    ok(close(FH), "Close output.zip");

    $ret = $frontend->get_results_page($job);
    like($ret, '/Job.*testjob.*has completed/',
         'get_results_page (successful job)');

    ok(open(FH, "> failure.log"), "Open failure.log");
    ok(close(FH), "Close failure.log");

    my $ret = $frontend->get_results_page($job);
    like($ret, '/was unable to complete your request/',
         '                 (failed job)');

    chdir("/");
}
