#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';

BEGIN {
    use_ok('allosmod');
}

my $t = new saliweb::Test('allosmod');

# Test get_navigation_links
{
    my $self = $t->make_frontend();
    my $links = $self->get_navigation_links();
    isa_ok($links, 'ARRAY', 'navigation links');
    like($links->[0], qr#<a href="http://modbase/top/">AllosMod Home</a>#,
         'Index link');
}

# Test get_index_page
{
    my $self = $t->make_frontend();
    my $txt = $self->get_index_page();
    like($txt, qr/AllosMod server/ms,
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
