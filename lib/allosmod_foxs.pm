package allosmod_foxs;
use base qw(saliweb::frontend);

use strict;

sub new {
    return saliweb::frontend::new(@_, @CONFIG@);
}

# Add our own JavaScript and CSS to the page header
sub get_start_html_parameters {
  my ($self, $style) = @_;
  my %param = $self->SUPER::get_start_html_parameters($style);
  push @{$param{-script}}, {-language => 'JavaScript',
                            -src => 'html/jquery-1.8.1.min.js' };
  push @{$param{-style}->{'-src'}}, 'html/allosmod_foxs.css';
  return %param;
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

sub make_dropdown {
    my ($self, $id, $title, $initially_visible, $text) = @_;
   
    my $style = "";
    if (!$initially_visible) {
      $style = " style=\"display:none\"";
    }
    return "<div class=\"dropdown_container\">\n" .
           "<a onclick=\"\$('#${id}').slideToggle('fast')\" " .
           "href=\"#\">$title</a>\n" .
           "<div class=\"dropdown\" id=\"${id}\"$style>\n" .
           $text . "\n</div></div>\n";
}

sub get_advanced_modeling_options {
    my $self = shift;
    my $q = $self->cgi;
    return $self->make_dropdown("advmodel", "Advanced Modeling Options", 0,
                $q->p("number of modeller models" .
                      $q->textfield({-name=>'NUM_MODELS', -value=>"10",
                                     -size=>"3"})) .
                $q->p("glycosylation sites" .
                      $q->filefield({-name=>"sugar_file"}) .
                      $q->checkbox({-name=>'flexible_glyc_sites',
                                    -label=>'flexible'}) . $q->br .
                      "number of optimization steps" .
                      $q->textfield({-name=>'number_of_steps_glyc',
                                     -size=>"3"})));
}

sub get_sampling_options {
    my $self = shift;
    my $q = $self->cgi;
    return $self->make_dropdown("sampling", "Sampling Options", 0,
      "<input type=\"radio\" name=\"sampletype\" value=\"multiconf\" " .
      "checked=\"checked\" onclick=\"\$('#rareconf').slideUp('fast'); " .
      "\$('#multiconf').slideDown('fast')\" />Sample most probable " .
      "conformations consistent with input crystal structure(s)" . $q->br .
      "<div class=\"sampopts\" id=\"multiconf\">\n" .
      "Number of runs " . $q->textfield({-name=>'NRUNS', -size=>"3",
                                         -value=>"30"}) .
      "MD temperature " . $q->textfield({-name=>'md_temperature', -size=>"3",
                                         -value=>"300"}) .
      "</div>\n\n" .

      "<input type=\"radio\" name=\"sampletype\" value=\"multiconf\" " .
      "onclick=\"\$('#multiconf').slideUp('fast'); " .
      "\$('#rareconf').slideDown('fast')\" />Sample low probability " .
      "conformations consistent with input crystal structure(s)" . $q->br .
      "<div class=\"sampopts\" id=\"rareconf\" style=\"display:none\">\n" .
      "Number of runs " . $q->textfield({-name=>'NRUNS', -size=>"3",
                                         -value=>"30"}) . $q->br .
      "MD temperature scanned or fixed value" .
                $q->textfield({-name=>'md_temperature', -size=>"3",
                               -value=>"300"}) . $q->br .
      "structural similarity % cut-off" .
                $q->textfield({-name=>'similarity_percentile', -size=>"3",
                               -value=>"10"}) .
      "</div>\n");
}

sub get_saxs_options {
    my $self = shift;
    my $q = $self->cgi;
    return $self->make_dropdown("saxs", "SAXS Options", 0,
                  $q->table(
                      $q->Tr($q->td('Maximal q Value'),
                             $q->td($q->textfield({-name=>'q', -size=>"10",
                                                   -value=>"0.5"}))),
                      $q->Tr($q->td('Profile Size'),
                             $q->td($q->textfield({-name=>'psize', -size=>"10",
                                                   -value=>"500"})),
                             $q->td('# of points in the computed profile')),
                      $q->Tr($q->td('Hydration Layer'),
                             $q->td('<input type="checkbox" name="hlayer" ' .
                                    'value="checked" />'),
                             $q->td('use hydration layer to improve fitting')),
                      $q->Tr($q->td('Excluded Volume Adjustment'),
                             $q->td('<input type="checkbox" name="exvolume" ' .
                                    'value="checked" />'),
                             $q->td('adjust the protein excluded volume ' .
                                    'to improve fitting')),
                      $q->Tr($q->td('Implicit Hydrogens'),
                             $q->td('<input type="checkbox" name="ihydrogens"' .
                                    ' value="checked" />'),
                             $q->td('implicitly consider hydrogen atoms')),
                      $q->Tr($q->td('Background Adjustment'),
                             $q->td('<input type="checkbox" name="background"' .
                                    ' value="checked" />'),
                             $q->td('adjust the background of the ' .
                                    'experimental profile')),
                      $q->Tr($q->td('Offset'),
                             $q->td('<input type="checkbox" name="offset"' .
                                    ' value="checked" />'),
                             $q->td('use offset in profile fitting')),
                  ));
}

sub get_all_advanced_options {
    my $self = shift;
    return $self->get_advanced_modeling_options() .
           $self->get_sampling_options() .
           $self->get_saxs_options();
}

sub get_sequence_or_alignment {
    my ($self, $alignment) = @_;
    my $q = $self->cgi;

    if (defined($alignment)) {
    } else {
    }
}

sub get_alignment {
    my $self = shift;
    my $q = $self->cgi;
    my $seq = $q->param('sequence');
    if (!defined($seq)) {
      return undef;
    }
    $seq =~ s/\s*//g;
    if ($seq eq "") {
      return undef;
    }

    my $nres = 0;
    my $ichain = 0;
    for (my $i = 0; $i < length($seq); $i++) {
      my $s = substr($seq, $i, 1);
      if ($s eq '/') {
        $ichain++;
      } else {
        $nres++;
      }
    }
    
    my $end_chain = chr(ord('A') + $ichain);
    my $aln = ">P1;pm.pdb\n" .
              "structureX:pm.pdb:1:A:${nres}:${end_chain}:::-1.00:-1.00";
    for (my $i = 0; $i < length($seq); $i += 75) {
      $aln .= "\n" . substr($seq, $i, 75);
    }
    $aln .= "*\n";
    return $aln;
}

sub get_index_page {
    my $self = shift;
    my $q = $self->cgi;

    my $alignment = $self->get_alignment();
    my $action = (defined($alignment) ? $self->submit_url : $self->index_url);

    my $form;
    if (defined($alignment)) {
      $form = $q->p("PDB code " . $q->textfield({-name=>'pdbcode',
                                              -size=>'5'}) .
                 " or upload file(s) " .
                 $q->filefield({-name=>'uploaded_file'})) .
           $q->p("Alignment:" . $q->br .
                   $q->textarea({-name=>'alignment', -rows=>5, -cols=>80,
                                 -value=>$alignment})) .
           $q->table(
               $q->Tr($q->td("Experimental profile"),
                      $q->td($q->filefield({-name=>"saxs_profile",
                                            -size=>"25"}))) .
               $q->Tr($q->td("Email address (optional)"),
                      $q->td($q->textfield({-name=>"email",
                                            -value=>$self->email,
                                            -size=>"25"})))) .
           $q->p("<center>" .
                 $q->input({-type=>"submit", -value=>"Submit"}) .
                 "</center>") .
           $self->get_all_advanced_options();
    } else {
      $form = $q->p("Sequence used in experiment:" . $q->br .
                    $q->textarea({-name=>'sequence', -rows=>5, -cols=>80})) .
              $q->p("<center>" .
                    $q->input({-type=>"submit", -value=>"Submit"}) .
                    "</center>");
    }

    my $greeting = <<GREETING;
<p>AllosMod-FoXS combines the <a href="http://modbase.compbio.ucsf.edu/allosmod/index.html"> AllosMod server</a> and 
<a href="http://modbase.compbio.ucsf.edu/foxs/index.html"> FoXS </a> web servers. Our combined server allows various 
sampling algorithms from AllosMod to generate structures that are directly inputed into FoXS for small angle X-ray 
scattering (SAXS) profile calculations.
<br />
<br />&nbsp;</p>
<br />&nbsp;</p>
GREETING
    return $q->h2({-align=>"center"},
                  "AllosMod-FoXS: Structure Generation and SAXS Profile Calculations") .
           $greeting .

           $q->start_form({-name=>"allosmod-foxsform", -method=>"post",
                           -action=>$action}) .
           $form .
           $q->end_form;
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
