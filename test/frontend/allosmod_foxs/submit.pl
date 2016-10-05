#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';
use File::Temp;

BEGIN {
    use_ok('allosmod_foxs');
}

my $t = new saliweb::Test('allosmod_foxs');

# Check job submission

# Check get_submit_page
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    ok(open(FH, "> saxs.profile"), "Open saxs.profile");
    print FH "0 0 0\n";
    ok(close(FH), "Close saxs.profile");
    open(FH, "saxs.profile");

    $self->{config}->{allosmod}->{script_directory} = "/bin/true ";

    $cgi->param('jobname', 'test');
    $cgi->param('alignment', 'testali.ali');
    $cgi->param('ligandmod_rAS', '3');
    $cgi->param('glycmod_nruns', '10');
    $cgi->param('glycmod_num_opt_steps', '1');
    $cgi->param('advancedopt', '');
    $cgi->param('thermodyn_nruns', '3');
    $cgi->param('multiconf_mdtemp', '300');
    $cgi->param('thermodyn_mdtemp', '300');
    $cgi->param('multiconf_nruns', '10');
    $cgi->param('rareconf_nruns', '3');
    $cgi->param('rareconf_mdtemp', 'scan');
    $cgi->param('rareconf_cdencutoff', '3.5');
    $cgi->param('rareconf_locrig', '0');
    $cgi->param('rareconf_break', '0');
    $cgi->param('addbond_indices', '');
    $cgi->param('addupper_indices', '');
    $cgi->param('addlower_indices', '');
    $cgi->param('sampletype', 'rareconf');
    $cgi->param('saxs_profile', \*FH);
    $cgi->param('comparativemod_nruns', '10');
    $cgi->param('saxs_qmax', '0.5');
    $cgi->param('saxs_psize', '500');
    $cgi->param('jobemail', '');
    my $ret = $self->get_submit_page();
    like($ret, qr/Job Submitted.*Your job has been submitted/ms,
         "submit page HTML");
    chdir('/') # Allow the temporary directory to be deleted
}
