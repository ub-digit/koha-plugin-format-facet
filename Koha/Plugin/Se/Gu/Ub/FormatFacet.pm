package Koha::Plugin::Se::Gu::Ub::FormatFacet;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## Include any Koha libraries we want to access
use C4::Context;
use C4::Members;
use C4::Auth;
use Koha::DateUtils;
use Koha::Libraries;
use Koha::Patron::Categories;
use Koha::Account;
use Koha::Account::Lines;
use MARC::Record;
use Cwd qw(abs_path);
use URI::Escape qw(uri_unescape);
use LWP::UserAgent;

use Koha::BiblioUtils;
use Switch;

## Here we set our plugin version
our $VERSION = "1.1.0";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Format Facet Plugin',
    author          => 'Johan Andersson von Geijer',
    date_authored   => '2017-11-07',
    date_updated    => "2017-12-28",
    minimum_version => '17.06.00.028',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin combines several marc fields and subfields '
      . 'into a new format facet. In order to decide wether a work is an '
      . 'e-book, a book or an article, one must look in several fields and subfields '
      . 'in the marc record. This creates a new custom marc record with that '
      . 'information in one place, leveraging facet-making.',
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub update_index_before {
    my ($self, $args) = @_;
    my $biblionums = $args->{'biblionums'};
    my $records = $args->{'records'};

    foreach my $record (@{$records}) {
        my $format_footprint = format_footprint($record);
        my $format = '';

        switch ($format_footprint) {
            case 'aa ' { $format = 'book'; }
            case 'aao' { $format = 'ebook'; }
            case 'aas' { $format = 'ebook'; }
            case 'ac ' { $format = 'book'; }
            case 'aco' { $format = 'ebook'; }
            case 'acs' { $format = 'ebook'; }
            case 'ad ' { $format = 'book'; }
            case 'ado' { $format = 'ebook'; }
            case 'ads' { $format = 'ebook'; }
            case 'am ' { $format = 'book'; }
            case 'amo' { $format = 'ebook'; }
            case 'ams' { $format = 'ebook'; }
            case 'as ' { $format = 'journal'; }
            case 'aso' { $format = 'ejournal'; }
            case 'ass' { $format = 'ejournal'; }
            case 'g  ' { $format = 'movie'; }
            case 'j  ' { $format = 'musicrecording'; }
            case 'i  ' { $format = 'otherrecording'; }
            case 'cm ' { $format = 'notatedmusic'; }
            case 'dm ' { $format = 'notatedmusic'; }
            case 'ai ' { $format = 'database'; }
            case 'ki ' { $format = 'database'; }
            case 'm  ' { $format = 'eresource'; }
            else { $format = 'other'; }
        }

        my $marc_field =  $self->retrieve_data('marc_field');
        my $marc_subfield =  $self->retrieve_data('marc_subfield');

        if (defined $record->subfield($marc_field, $marc_subfield)) {
            #print "Skip since marc field $marc_field#$marc_subfield allready exists!\n";
        } else {
            #print "Using marc field $marc_field#$marc_subfield!\n";
            my $before_field = $record->field('999');
            my $new_field = MARC::Field->new($marc_field,'','',$marc_subfield => "$format");
            $record->insert_fields_before($before_field,$new_field);
        }
    }

    # use Data::Dumper;
    # open(DEBUG, '>/var/tmp/format_facet.log');
    # print DEBUG Dumper($args);
    # close(DEBUG);

    return $args;
}

sub format_footprint {
    my ($record) = @_;
    my $leader = $record->leader();

    my $footprint .= type_of_record($leader);
    $footprint.= bibliographic_level($leader);
    $footprint .= form_of_item($record);

    return "$footprint";
}

sub type_of_record {
    my ($leader) = @_;

    return substr($leader, 6, 1);
}

sub bibliographic_level {
    my ($leader) = @_;

    return substr($leader, 7, 1);
}

sub form_of_item {
    my ($record) = @_;
    my $field = $record->field('008');
    return defined $field ? substr($field->data(), 23, 1) : ' ';
}

sub is_dbas {
    my ($record) = @_;
    my $data = $record->subfield('042', "9");
    return defined $data && $data eq 'DBAS';
}


# If your tool is complicated enough to needs it's own setting/configuration
# you will want to add a 'configure' method to your plugin like so.
# Here I am throwing all the logic into the 'configure' method, but it could
# be split up like the 'report' method is.
sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $libraries = Koha::Libraries->as_list();

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'configure.tt' });

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            marc_field => $self->retrieve_data('marc_field'),
            marc_subfield => $self->retrieve_data('marc_subfield'),
        );
        print $cgi->header(-charset => 'utf-8' );
        print $template->output();
    }
    else {
        $self->store_data(
            {
                marc_field => $cgi->param('marc_field'),
                marc_subfield => $cgi->param('marc_subfield'),
            }
        );
        $self->go_home();
    }
}



sub install {
    my ($self, $args) = @_;
    return 1;
}

sub uninstall {
    my ($self, $args) = @_;
    return 1;
}



1;
