package allosmod_foxs;
use base qw(saliweb::frontend);

use strict;

sub new {
    return saliweb::frontend::new(@_, @CONFIG@);
}

sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->index_url}, "AllosMod-FoXS Home"),
        $q->a({-href=>$self->help_url}, "About AllosMod-FoXS"),
        $q->a({-href=>$self->queue_url}, "Queue"),
        $q->a({-href=>$self->contact_url}, "Contact Us"),
	$q->a({-href=>$self->cgiroot . "/help.cgi?type=resources"},"Resources")
        ];
}

sub get_project_menu {
    my $self = shift;
    my $version = $self->version;
    my $htmlroot = $self->htmlroot;
    return <<MENU;
<div id="logo">
<left>
<a href="http://modbase.compbio.ucsf.edu/allosmod-foxs"><img src="$htmlroot/img/am_logo.gif" /></a>
</left>
</div><br />
<h4><small>Developers:</small></h4><p>Dina Schneidman & Patrick Weinkam</p>
<h4><small>Acknowledgements:</small></h4>
<p>Ben Webb<br />
Elina Tjioe<br />
Ursula Pieper<br />
<br />
Andrej Sali</p>
<p><i>Version $version</i></p>
MENU
#<p>&nbsp;</p>
}

sub get_footer {
    my $self = shift;
    my $htmlroot = $self->htmlroot;
    return <<FOOTER;
<div id="address">
<center><a href="http://www.ncbi.nlm.nih.gov/pubmed/22403063">
<b>P. Weinkam, J. Pons, and A. Sali, Proc Natl Acad Sci U S A., (2012) <i>109 (13),</i> 4875-4880</b></a>:
<a href="$htmlroot/file/Weinkam_PNAS_2012.pdf"><img src="$htmlroot/img/pdf.gif" /></a>,
S.I.:<a href="http://modbase.compbio.ucsf.edu/allosmod/html/file/Weinkam_PNAS_2012_si.pdf"><img src="$htmlroot/img/pdf.gif" /></a>
</center>
</div>
FOOTER
}

sub get_index_page {
    my $self = shift;
    my $q = $self->cgi;
    my $greeting = <<GREETING;
<p>AllosMod-FoXS combines the <a href="http://modbase.compbio.ucsf.edu/allosmod/index.html"> AllosMod server</a> and 
<a href="http://modbase.compbio.ucsf.edu/foxs/index.html"> FoXS </a> web servers. Our combined server allows various 
sampling algorithms from AllosMod to generate structures that are directly inputed into FoXS for small angle X-ray 
scattering (SAXS) profile calculations.
<br />
<br />&nbsp;</p>
<br />&nbsp;</p>
GREETING
    return "<div id=\"resulttable\">\n" .
           $q->h2({-align=>"center"},
                  "AllosMod-FoXS: Structure Generation and SAXS Profile Calculations") .

           $q->start_form({-name=>"allosmod-foxsform", -method=>"post",
                           -action=>$self->submit_url}) .
           $q->end_form .
           "</div>\n";
}

sub get_submit_page {
    my $self = shift;
    my $q = $self->cgi;

    my $user_pdb      = $q->upload('uploaded_file');              # uploaded file handle
    my $user_name     = $q->param('name')||"";          # user-provided job name
    my $user_saxs      = $q->upload('saxs_profile');              # uploaded file handle
    my $user_pdbcode     = $q->param('PDB code')||"";          # user-provided job name
    my $email         = $q->param('email')||undef;      # user's e-mail

    my $job = $self->make_job($user_name);
    my $jobdir = $job->directory;

    #write uploaded files

    #submit job
    $job->submit($email);

    ## write subject details into a file and pop up an exit page
    my $return=
      $q->h1("Job Submitted") .
      $q->hr .
      $q->p("Your job has been submitted to the server! " .
            "Your job ID is " . $job->name . ".") .
      $q->p("Results will be found at <a href=\"" .
            $job->results_url . "\">this link</a>.");
    if ($email) {
        $return.=$q->p("You will be notified at $email when job results " .
                       "are available.");
    }

    $return .=
      $q->p("You can check on your job at the " .
            "<a href=\"" . $self->queue_url .
            "\">AllosMod-FoXS queue status page</a>.").
      $q->p("If you experience a problem or you do not receive the results " .
            "for more than 12 hours, please <a href=\"" .
            $self->contact_url . "\">contact us</a>.") .
      $q->p("Thank you for using AllosMod-FoXS!").
      $q->p("<br />- Dina Schneidman and Patrick Weinkam");

    return $return;
}

sub allow_file_download {
    my ($self, $file) = @_;
    return $file eq 'output.zip';
}

sub get_results_page {
    my ($self, $job) = @_;
    my $q = $self->cgi;
    if (-f 'output.zip') {
        return $self->display_ok_job($q, $job);
    } else {
        return $self->display_failed_job($q, $job);
    }
}

sub display_ok_job {
    my ($self, $q, $job) = @_;
    my $return= $q->p("Job '<b>" . $job->name . "</b>' has completed, thank you for using AllosMod-FoXS!");

    $return .= $job->get_results_available_time();
    return $return;
}

sub display_failed_job {
    my ($self, $q, $job) = @_;
    my $return= $q->p("AllosMod-FoXS was unable to complete your request: job '<b>" . $job->name);
    $return.= $q->p("For more information, you can " .
                    "<a href=\"" . $job->get_results_file_url("failure.log") .
                    "\">download the log file</a>." .
                    "If the problem is not clear from this log, " .
                    "please <a href=\"" .
                    $self->contact_url . "\">contact us</a> for " .
                    "further assistance.");
    return $return;
}

sub get_help_page {
    my ($self, $display_type) = @_;
    if ($display_type eq "resources") {
	return $self->get_text_file("resources.txt");
    } elsif ($display_type eq "glyc") {
	return $self->get_text_file("help_glyc.txt");
    } else {
	return $self->SUPER::get_help_page($display_type);
    }
}

1;
