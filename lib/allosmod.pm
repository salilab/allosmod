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
        $q->a({-href=>$self->index_url}, "AllosMod Home"),
        $q->a({-href=>$self->help_url}, "About AllosMod"),
#        $q->a({-href=>$self->cgiroot . "/help.cgi?type=help"},"About AllosMod"),
        $q->a({-href=>$self->queue_url}, "AllosMod Queue"),
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
<a href="http://modbase.compbio.ucsf.edu/allosmod"><img src="$htmlroot/img/am_logo.gif" /></a>
</left>
</div><br />
<h4><small>Developer:</small></h4><p>Patrick Weinkam</p>
<h4><small>Acknowledgements:</small></h4>
<p>Elina Tjioe<br />
Ben Webb<br />
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
<p>AllosMod is a web server to set up simulations that can be run in 
MODELLER. AllosMod creates a model of a protein\'s energy landscape. 
Carefully designed energy landscapes allow efficient molecular 
dynamics sampling at constant temperatures, thereby providing ergodic 
sampling of conformational space. Use AllosMod to:<br />
<ul>
- Model energy landscapes for a protein with known/modeled ligand bound and unbound structures <br />
- Model energy landscapes for a protein with one known/modeled structure to predict lowly populated ensembles <br />
- Model energy landscapes for glycosylated proteins (For help, click <a href="http://modbase.compbio.ucsf.edu/allosmod/help.cgi?type=glyc"> here</a>) <br />
- Fast sampling for any of the above landscapes <br />
</ul>

The AllosMod server allows batch jobs to set up many simulations at 
once. Upload a zip file containing directories for each 
type of landscape that you want to create. AllosMod will set up many short 
simulations for each landscape. There are two options for sampling: 1) constant temperature 
simulation at 300 K for 6 ns, which will be completed overnight on a single processor on the 
user\'s computer or 2) sampling is performed using a quick, unequilibrated simulation at 300 K.
Sampling is acheived efficiently by starting each simulation at different points in conformational 
space and by storing the energies in memory. <br />
<br />
AllosMod has several options for conformational sampling and contains tools for simulation analysis. 
The AllosMod server is integrated with the <a href="http://modbase.compbio.ucsf.edu/foxs/index.html"> FoXS server</a>
for structure-based calculation of small angle X-ray scattering profiles (in progress). For more 
details click on the "About AllosMod" link above and read the paper listed below. <br />
<br />
***<a style="color:red">NEW</a>*** AllosMod will run quick, constant temperature simulations of your 
                        modeled energy landscape on our servers, see "About AllosMod" for details.
<br />&nbsp;</p>
GREETING
    return "<div id=\"resulttable\">\n" .
           $q->h2({-align=>"center"},
                  "AllosMod: Modeling of Ligand-induced Protein Dynamics and Beyond") .
           $q->start_form({-name=>"allosmodform", -method=>"post",
                           -action=>$self->submit_url}) .
           $q->table(
               $q->Tr($q->td({-colspan=>2}, $greeting)) .

               $q->Tr($q->td($q->h3("AllosMod Inputs"))) .

               $q->Tr($q->td("Email address (optional)",
                             $self->help_link("general")),
                      $q->td($q->textfield({-name=>"email",
                                            -value=>$self->email,
                                            -size=>"25"}))) .

               $q->Tr($q->td("Upload directories zip file",
                             $self->help_link("file"), $q->br),
                      $q->td($q->filefield({-name=>"zip"}))) .

               $q->Tr($q->td("Name your model",
                                    $self->help_link("name")),
                      $q->td($q->textfield({-name=>"name",
                                            -value=>"hemoglobin", -size=>"25"}))) .

               $q->Tr($q->td($q->h3("***Before running simulations, click here: ",
                                    $self->help_link("run")))) .

               $q->Tr($q->td($q->h3("To analyze simulations, click here: ",
                                    $self->help_link("analysis")))) .

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
      $q->p("Your MODELLER input files should be finished shortly, depending on the number of landscapes to be created. ").
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
    my $return= $q->p("Job '<b>" . $job->name . "</b>' has completed, thank you for using AllosMod!");

    $return.= $q->p("<a href=\"" . $job->get_results_file_url("output.zip") .
                    "\">Download output zip file.</a>");
    $return.=$q->p("<br />It would be wise to double check your run directories: <br /> 1) check that " .
		   "allostericsite.pdb correctly represents the allosteric site (if applicable) <br /> 2) if some" .
		   "directories were not set up correctly, then read error.log. <br />");
    $return .= $job->get_results_available_time();
    return $return;
}

sub display_failed_job {
    my ($self, $q, $job) = @_;
    my $return= $q->p("AllosMod was unable to complete your request: job '<b>" . $job->name);
    $return.=$q->p("This is usually caused by incorrect inputs " .
                   "(e.g. alignment file, PDB files, etc.).");
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
