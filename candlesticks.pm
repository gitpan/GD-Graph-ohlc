#==========================================================================
#              Copyright (c) 2008 Paul Miller
#==========================================================================
 
package GD::Graph::candlesticks;

use strict;
use warnings;

use GD::Graph::mixed; # NOTE: we pull this in so we can modify part of it.
use GD::Graph::axestype;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours);

use constant PI => 4 * atan2(1,1);

our $VERSION = "0.9605";
our @ISA = qw(GD::Graph::axestype);

our %DEFAULT = (
    correct_width => 1,
    candlestick_width => 7,
);

push @GD::Graph::mixed::ISA, __PACKAGE__;

# working off gdgraph/Graph/bars.pm (in addition to ohlc.pm)

# _has_default {{{
sub _has_default {
    my $this = shift;

    return $DEFAULT{$_[0]} if exists $DEFAULT{$_[0]};
    return $this->SUPER::_has_default(@_);
}
# }}}
# draw_data_set {{{
sub draw_data_set {
    my $this = shift;
    my $ds   = shift;

    my @values = $this->{_data}->y_values($ds) or
        return $this->_set_error("Impossible illegal data set: $ds", $this->{_data}->error);

    # Pick a colour
    my $dsci = $this->set_clr($this->pick_data_clr($ds));

    my $GX;
    my ($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy); # NOTE: all the x's are the same...
    for (my $i = 0; $i < @values; $i++) {
        my $value = $values[$i];
        next unless ref($value) eq "ARRAY" and @$value==4;
        my ($open, $high, $low, $close) = @$value;

        if (defined($this->{x_min_value}) && defined($this->{x_max_value})) {
            $GX = $this->{_data}->get_x($i);

            ($ox, $oy) = $this->val_to_pixel($GX, $value->[0], $ds);
            ($hx, $hy) = $this->val_to_pixel($GX, $value->[1], $ds);
            ($lx, $ly) = $this->val_to_pixel($GX, $value->[2], $ds);
            ($cx, $cy) = $this->val_to_pixel($GX, $value->[3], $ds);

        } else {
            ($ox, $oy) = $this->val_to_pixel($i+1, $value->[0], $ds);
            ($hx, $hy) = $this->val_to_pixel($i+1, $value->[1], $ds);
            ($lx, $ly) = $this->val_to_pixel($i+1, $value->[2], $ds);
            ($cx, $cy) = $this->val_to_pixel($i+1, $value->[3], $ds);
        }

        $this->candlesticks_marker($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy, $dsci );
        $this->{_hotspots}[$ds][$i] = ['rect', $this->candlesticks_marker_coordinates($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy)];
    }

    return $ds;
}
# }}}
# half_width {{{
sub half_width {
    my $this = shift;

    return int( $this->{candlestick_width} / 2 ) if exists $this->{candlestick_width};
    return 3;
}
# }}}
# candlesticks_marker_coordinates {{{
sub candlesticks_marker_coordinates {
    my $this = shift;
    my ($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy) = @_;

    my $h = $this->half_width;
    return ( $ox - $h, $cx + $h, $hy, $ly );
}
# }}}
# candlesticks_marker {{{
sub candlesticks_marker {
    my $this = shift;
    my ($ox,$oy, $cx,$cy, $lx,$ly, $hx,$hy, $mclr) = @_;
    return unless defined $mclr;

    $this->{graph}->line( ($lx,$ly) => ($hx,$hy), $mclr );

    my $h = $this->half_width;
    if( $cy>$oy ) {
        $this->{graph}->filledRectangle( ($cx - $h, $cy) => ($ox + $h, $oy), $mclr );

    } else {
        $this->{graph}->filledRectangle( ($cx - $h, $cy) => ($ox + $h, $oy), $this->{bgci} );
        $this->{graph}->rectangle(       ($cx - $h, $cy) => ($ox + $h, $oy), $mclr );
    }

    return;
}
# }}}

1;
