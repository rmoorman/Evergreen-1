package OpenILS::WWW::EGCatLoader;
use strict; use warnings;
use Apache2::Const -compile => qw(OK DECLINED FORBIDDEN HTTP_INTERNAL_SERVER_ERROR REDIRECT HTTP_BAD_REQUEST);
use OpenSRF::Utils::Logger qw/$logger/;
use OpenILS::Utils::CStoreEditor qw/:funcs/;
use OpenILS::Utils::Fieldmapper;
use OpenILS::Application::AppUtils;
my $U = 'OpenILS::Application::AppUtils';

# context additions: 
#   library : aou object
#   parent: aou object
sub load_library {
    my $self = shift;
    my %kwargs = @_;
    my $ctx = $self->ctx;
    $ctx->{page} = 'library';  

    $self->timelog("load_library() began");

    my $lib_id = $ctx->{page_args}->[0];
    $lib_id = $self->_resolve_org_id_or_shortname($lib_id);

    return Apache2::Const::HTTP_BAD_REQUEST 
        unless $lib_id;

    my $aou = $ctx->{get_aou}->($lib_id);
    my $sname = $aou->parent_ou;

    $ctx->{library} = $aou;
    if ($aou->parent_ou) {
        $ctx->{parent} = $ctx->{get_aou}->($aou->parent_ou);
    }

    $self->timelog("got basic lib info");

    # Get mailing address
    if ($aou->mailing_address) {
        my $session = OpenSRF::AppSession->create("open-ils.actor");
        $ctx->{mailing_address} =
            $session->request('open-ils.actor.org_unit.address.retrieve',
            $aou->mailing_address)->gather(1);
    }

    # Get current hours of operation
    my $hours = $self->editor->retrieve_actor_org_unit_hours_of_operation($lib_id);
    if ($hours) {
        $ctx->{hours} = $hours;
        # Generate naive schema.org format
        $ctx->{hours_schema} = "Mo " . substr($hours->dow_0_open, 0, 5) . "-" . substr($hours->dow_0_close, 0, 5) .
            ",Tu " . substr($hours->dow_1_open, 0, 5) . "-" . substr($hours->dow_1_close, 0, 5) .
            ",We " . substr($hours->dow_2_open, 0, 5) . "-" . substr($hours->dow_2_close, 0, 5) .
            ",Th " . substr($hours->dow_3_open, 0, 5) . "-" . substr($hours->dow_3_close, 0, 5) .
            ",Fr " . substr($hours->dow_4_open, 0, 5) . "-" . substr($hours->dow_4_close, 0, 5) .
            ",Sa " . substr($hours->dow_5_open, 0, 5) . "-" . substr($hours->dow_5_close, 0, 5) .
            ",Su " . substr($hours->dow_6_open, 0, 5) . "-" . substr($hours->dow_6_close, 0, 5);
    }

    return Apache2::Const::OK;
}

1;
