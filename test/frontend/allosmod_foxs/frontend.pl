#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';
use File::Temp;
use Test::Exception;
use Test::MockModule;

BEGIN {
    use_ok('allosmod_foxs');
}

my $t = new saliweb::Test('allosmod_foxs');

# Test get_navigation_links
{
    my $self = $t->make_frontend();
    my $links = $self->get_navigation_links();
    isa_ok($links, 'ARRAY', 'navigation links');
    like($links->[0], qr#<a href="http://modbase/top/">AllosMod-FoXS Home</a>#,
         'Index link');
}

# Test get_page_is_responsive
{
    my $self = $t->make_frontend();
    is($self->get_page_is_responsive('index'), 1, 'index page responsive');
}

# Test get_index_page
{
    my $self = $t->make_frontend();
    my $txt = $self->get_index_page();
    like($txt, qr/AllosMod\-FoXS: Structure Generation and SAXS/ms,
         'get_index_page');
}

# Test get_index_page, single job
{
    my $self = $t->make_frontend();
    my $job = $self->make_job('testjob', 'noemail');

    # Force get_alignment() to return as for single job mode
    my $module = new Test::MockModule('allosmod_foxs');
    $module->mock('get_alignment', sub { return 'dummyaln', $job; });

    my $txt = $self->get_index_page();
    like($txt, '/AllosMod\-FoXS: Structure Generation and SAXS' .
               '.*Alignment:.*dummyaln.*testjob/ms',
         'get_index_page');
}

# Test get_start_html_parameters
{
    my $self = $t->make_frontend();
    my %p = $self->get_start_html_parameters();
}

# Test get_project_menu
{
    my $self = $t->make_frontend();
    my $txt = $self->get_project_menu();
    like($txt, qr/Developers.*Version/ms,
         'get_project_menu');
}

# Test get_footer
{
    my $self = $t->make_frontend();
    my $txt = $self->get_footer();
    like($txt, qr/Weinkam.*PNAS/ms,
         'get_footer');
}

# Test make_dropdown
{
    my $self = $t->make_frontend();
    my $txt = $self->make_dropdown("testid", "mytitle", 1, "test text");
    like($txt, qr/div class="dropdown_container".*id="testid"/ms,
         'make_dropdown');

    $txt = $self->make_dropdown("testid", "mytitle", 0, "test text");
    like($txt, qr/style="display:none"/ms,
         'make_dropdown (invisible)');
}

# Test get_advanced_modeling_options
{
    my $self = $t->make_frontend();
    my $txt = $self->get_advanced_modeling_options();
    like($txt, qr/Advanced Modeling Options.*residue contact energies/ms,
         'get_advanced_modeling_options');
}

# Test get_sampling_options
{
    my $self = $t->make_frontend();
    my $txt = $self->get_sampling_options();
    like($txt, qr/Sampling Options.*residue charge density/ms,
         'get_sampling_options');
}

# Test get_all_advanced_options
{
    my $self = $t->make_frontend();
    my $txt = $self->get_all_advanced_options();
    like($txt, '/Advanced Modeling Options.*residue contact energies.*' .
               'Sampling Options.*residue charge density/ms',
         'get_all_advanced_options');
}

# Test get_help_page
{
    my $self = $t->make_frontend();
    $self->{server_name} = "allosmod_foxs";
    my $txt = $self->get_help_page("resources");
    $txt = $self->get_help_page("glyc");
    $txt = $self->get_help_page("contact");
    # Can't assert that the content is OK, because we're probably in the
    # wrong directory to find it
}

# Test write_uploaded_file
{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);

    ok(open(FH, "> $tmpdir/in.file"), "Open in.file");
    print FH "garbage\n";
    ok(close(FH), "Close in.file");
    ok(open(FH, "< $tmpdir/in.file"), "Open in.file");

    throws_ok { allosmod_foxs::write_uploaded_file(\*FH, "/foo/bar/out.file") }
              qr/Cannot open/, "write_uploaded file, open failure";

    allosmod_foxs::write_uploaded_file(\*FH, "$tmpdir/out.file");

    ok(open(FH, "< $tmpdir/out.file"), "Open out.file");
    my $contents = <FH>;
    is($contents, "garbage\n", "Check out.file contents");
    close(FH);
}

# Test delete_file_if_empty
{
    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);

    my $fname = "$tmpdir/in.file";
    ok(open(FH, "> $fname"), "Open in.file");
    ok(close(FH), "Close in.file");
    ok(-e $fname, "file created ok");

    allosmod_foxs::delete_file_if_empty($fname);
    ok(! -e $fname, "file deleted ok");

    ok(open(FH, "> $fname"), "Open in.file");
    print FH "contents\n";
    ok(close(FH), "Close in.file");
    ok(-e $fname, "file created ok");

    allosmod_foxs::delete_file_if_empty($fname);
    ok(-e $fname, "file not deleted");
}
