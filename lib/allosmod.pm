package allosmod;
use base qw(saliweb::frontend);

use strict;

sub new {
    return saliweb::frontend::new(@_, @CONFIG@);
}

sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->index_url}, "Allostery Model Home"),
        $q->a({-href=>$self->queue_url}, "Allostery Model Current queue"),
        $q->a({-href=>$self->help_url}, "Allostery Model Help"),
        $q->a({-href=>$self->contact_url}, "Allostery Model Contact")
        ];
}

sub get_project_menu {
    my $self = shift;
    my $version = $self->version;
    return <<MENU;
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<h4><small>Developer:</small></h4><p>Patrick Weinkam</p>
<h4><small>Acknowledgements:</small></h4>
<p>Elina Tjioe<br />
Ben Webb<br />
Ursula Pieper<br />
<br />
Andrej Sali</p>
<p><i>Version $version</i></p>
MENU
}

sub get_footer {
    my $self = shift;
    my $htmlroot = $self->htmlroot;
    return <<FOOTER;
<div id="address">
<center><a href="http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=pubmed&amp;cmd=Retrieve&amp;dopt=AbstractPlus&amp;list_uids=11045621&amp;query_hl=2&amp;itool=pubmed_docsum">
<b>P. Weinkam, J. Pons, and A. Sali, Proc Natl Acad Sci U S A., (2012) <i>V,</i> X-Y</b></a>
<a href="http://salilab.org/pdf/Fiser_ProteinSci_2000.pdf"><img src="$htmlroot/img/pdf.gif" /></a>
</center>
</div>
FOOTER
}

sub get_index_page {
    my $self = shift;
    my $q = $self->cgi;
    my $greeting = <<GREETING;
<p>AllosMod is a web server to set up simulations that can be run in 
MODELLER. AllosMod creates a model of a protein\'s energy landscape. 
Carefully designed energy landscapes allow efficient molecular 
dynamics sampling at constant temperatures, thereby providing ergodic 
sampling of conformational space. AllosMod was designed to study 
transitions in large allosteric proteins but may be used to 
study protein dynamics in general.
<br />&nbsp;</p>
GREETING
    return "<div id=\"resulttable\">\n" .
           $q->h2({-align=>"center"},
                  "AllosMod: Modeling of Ligand-induced Protein Dynamics and Beyond") .
           $q->start_form({-name=>"allosmodform", -method=>"post",
                           -action=>$self->submit_url}) .
           $q->table(
               $q->Tr($q->td({-colspan=>2}, $greeting)) .
               $q->Tr($q->td($q->h3("AllosMod Inputs",
                                    $self->help_link("general")))) .
               $q->Tr($q->td("Email address (optional)",
                             $self->help_link("email")),
                      $q->td($q->textfield({-name=>"email",
                                            -value=>$self->email,
                                            -size=>"25"}))) .
               $q->Tr($q->td("Upload directories zip file",
                             $self->help_link("file"), $q->br),
                      $q->td($q->filefield({-name=>"zip"}))) .
#               $q->Tr($q->td("Number of runs per directory",
#			     $self->help_link("numrun"), $q->br),
#                      $q->td($q->textfield({-name=>"numrun",
#                                            -value=>10,-maxlength=>"3", -size=>"5"}))) .
               $q->Tr($q->td($q->h3("Name your model",
                                    $self->help_link("name"))),
                      $q->td($q->textfield({-name=>"name",
                                            -value=>"hemoglobin", -size=>"25"}))) .
               $q->Tr($q->td({-colspan=>"2"},
                             "<center>" .
                             $q->input({-type=>"submit", -value=>"RUN!"}) .
                             $q->input({-type=>"reset", -value=>"Reset"}) .
                             "</center><p>&nbsp;</p>"))) .
           $q->end_form .
           "</div>\n";
}

sub get_submit_page {
    my $self = shift;
    my $q = $self->cgi;

    my $user_zip      = $q->upload('zip');              # uploaded file handle
    my $user_name     = $q->param('name')||"";          # user-provided job name
    my $email         = $q->param('email')||undef;      # user's e-mail
#    my $user_numrun   = $q->param('numrun');     # number of runs per dir

#    check_optional_email($email);
    check_zip($user_zip);
#    check_numrun($user_numrun);

    my $job = $self->make_job($user_name);
    my $jobdir = $job->directory;

    #write uploaded files
    my $zipfile = "$jobdir/input.zip";
    open(UPLOAD, "> $zipfile")
	or throw saliweb::frontend::InternalError("Cannot open $zipfile: $!");
    my $file_contents = "";
    while (<$user_zip>) {
        $file_contents .= $_;
    }
    print UPLOAD $file_contents;
    close UPLOAD
	or throw saliweb::frontend::InternalError("Cannot close $zipfile: $!");

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
            "\">AllosMod queue status page</a>.").
      $q->p("Your MODELLER input files should be finished within 10 mins, depending on the load").
      $q->p("If you experience a problem or you do not receive the results " .
            "for more than 12 hours, please <a href=\"" .
            $self->contact_url . "\">contact us</a>.") .
      $q->p("Thank you for using AllosMod!").
      $q->p("<br />- Patrick Weinkam");

    return $return;
}

# Check if a PDB name was specified
sub check_zip {
    my ($zip) = @_;
    if (!$zip) {
        throw saliweb::frontend::InputValidationError(
                       "No directories zip file has been submitted!");
    }
}

#check if number of runs specified is appropriate
sub check_numrun {
    my ($self, $numrun) = @_;
    if (!$numrun) {
        throw saliweb::frontend::InputValidationError(
                       "Numrun not specified!");
    }
    if ($numrun == 0) {
        throw saliweb::frontend::InputValidationError(
                       "Numrun must be greater than zero!");
    }
    if ($numrun > 100) {
        throw saliweb::frontend::InputValidationError(
                       "Numrun must be less than 100!");
    }
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
    my $return= $q->p("Job '<b>" . $job->name . "</b>' has completed.");

    $return.= $q->p("<a href=\"" . $job->get_results_file_url("output.zip") .
                    "\">Download output zip file containing run directories.</a>.");
    $return .= $job->get_results_available_time();
    return $return;
}

sub display_failed_job {
    my ($self, $q, $job) = @_;
    my $return= $q->p("AllosMod was unable to complete your request, job'<b>" . $job->name);
    $return.=$q->p("This is usually caused by incorrect inputs " .
                   "(e.g. directories zip file, PDB files, etc.).");
    $return.=$q->p("For a discussion of some common input errors, please see " .
                   "the " .
                   $q->a({-href=>$self->help_url . "#errors"}, "help page") .
                   ".");
    $return.= $q->p("For more information, you can " .
                    "<a href=\"" . $job->get_results_file_url("failure.log") .
                    "\">download the log file</a>." .
                    "If the problem is not clear from this log, " .
                    "please <a href=\"" .
                    $self->contact_url . "\">contact us</a> for " .
                    "further assistance.");
    return $return;
}

1;
