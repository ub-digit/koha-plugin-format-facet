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
our $VERSION = "0.0.2";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Format Facet Plugin',
    author          => 'Johan Andersson von Geijer',
    date_authored   => '2017-11-07',
    date_updated    => "2017-12-04",
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
            case 'aa ' { $format = 'book'; print "Bok\n"; }
            case 'aao' { $format = 'ebook'; print "E-bok\n"; }
            case 'aas' { $format = 'ebook'; print "E-bok\n"; }
            case 'ac ' { $format = 'book'; print "Bok\n"; }
            case 'aco' { $format = 'ebook'; print "E-bok\n"; }
            case 'acs' { $format = 'ebook'; print "E-bok\n"; }
            case 'ad ' { $format = 'book'; print "Bok\n"; }
            case 'ado' { $format = 'ebook'; print "E-bok\n"; }
            case 'ads' { $format = 'ebook'; print "E-bok\n"; }
            case 'am ' { $format = 'book'; print "Bok\n"; }
            case 'amo' { $format = 'ebook'; print "E-bok\n"; }
            case 'ams' { $format = 'ebook'; print "E-bok\n"; }
            case 'as ' { $format = 'journal'; print "Tidskrift\n"; }
            case 'aso' { $format = 'ejournal'; print "E-tidskrift\n"; }
            case 'ass' { $format = 'ejournal'; print "E-tidskrift\n"; }
            case 'g  ' { $format = 'movie'; print "Film/video\n"; }
            case 'j  ' { $format = 'musicrecording'; print "Musikinspelning\n"; }
            case 'i  ' { $format = 'soundrecording'; print "Inspelning övrig\n"; }
            case 'cm ' { $format = 'notatedmusic'; print "Musiktryck (noter)\n"; }
            case 'dm ' { $format = 'notatedmusic'; print "Musiktryck (noter)\n"; }
            case 'ai ' { $format = 'database'; print "Databas\n" if is_dbas($record); }
            case 'ki ' { $format = 'database'; print "Databas\n" if is_dbas($record); }
            case 'm  ' { $format = 'computergame'; print "Elektronisk resurs\n"; }
            else { $format = 'other'; print "Unhandled format!\n"; }
        }

        my $marc_field =  $self->retrieve_data('marc_field');
        my $marc_subfield =  $self->retrieve_data('marc_subfield');

        if (defined $record->subfield($marc_field, $marc_subfield)) {
            print "998 is Allready there!";
        } else {
            my $before_field = $record->field('999');
            my $new_field = MARC::Field->new($marc_field,'','',$marc_subfield => "$format");
            $record->insert_fields_before($before_field,$new_field);
        }

        print "Format: [$format] Footprint: [$format_footprint]\n";
        print "================\n";
    }

    use Data::Dumper;
    open(DEBUG, '>/var/tmp/format_facet.log');
    print DEBUG Dumper($args);
    close(DEBUG);

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

    return substr($record->field('008')->data(), 23, 1);
}

sub is_dbas {
    my ($record) = @_;

    if (defined $record->subfield('042', "9") && $record->subfield('042', "9") eq 'DBAS') {
        return 1;
    } else {
        return 0;
    }
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
