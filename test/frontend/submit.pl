#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';
use File::Temp;
use Test::Exception;

BEGIN {
    use_ok('allosmod');
}

my $t = new saliweb::Test('allosmod');

# Check job submission

sub get_submit_frontend {
    my ($t) = @_;
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

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
    return $self;
}

# Check get_submit_page
{
    my $self = get_submit_frontend($t);
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");
    my $ret = $self->get_submit_page();
    like($ret, qr/Job Submitted.*Your job has been submitted/ms,
         "submit page HTML");
    chdir('/') # Allow the temporary directory to be deleted
}

# Check bad options to get_submit_page
{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    my $self = get_submit_frontend($t);
    $self->cgi->param('ligandmod_rAS', 'garbage');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad radius";
    like($@, qr/Please provide a sensible radius/, "exception message");

    my $self = get_submit_frontend($t);
    $self->cgi->param('glycmod_nruns', '110');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad num models for glyc";
    like($@, qr/number of models for glyc/, "exception message");

    my $self = get_submit_frontend($t);
    $self->cgi->param('glycmod_num_opt_steps', '11');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad num steps for glyc";
    like($@, qr/number of models for glyc/, "exception message");

    my $self = get_submit_frontend($t);
    $self->cgi->param('thermodyn_nruns', '101');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad num of thermodyn runs";
    like($@, qr/sensible number of runs/, "exception message");

    my $self = get_submit_frontend($t);
    $self->cgi->param('thermodyn_mdtemp', 'garbage');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad thermodyn temp";
    like($@, qr/sensible MD temperature for probable/, "exception message");

    chdir('/') # Allow the temporary directory to be deleted
}
