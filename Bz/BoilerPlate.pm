package Bz::BoilerPlate;
use Bz;
use Moo;

use File::Slurp;

use constant BOILER_PLATES => {
    css => <<EOF,
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This Source Code Form is "Incompatible With Secondary Licenses", as
 * defined by the Mozilla Public License, v. 2.0. */
EOF

    js => <<EOF,
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This Source Code Form is "Incompatible With Secondary Licenses", as
 * defined by the Mozilla Public License, v. 2.0. */
EOF

    pl => <<EOF,
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.
EOF

    pm => <<EOF,
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.
EOF

    tmpl => <<EOF,
[%# This Source Code Form is subject to the terms of the Mozilla Public
  # License, v. 2.0. If a copy of the MPL was not distributed with this
  # file, You can obtain one at http://mozilla.org/MPL/2.0/.
  #
  # This Source Code Form is "Incompatible With Secondary Licenses", as
  # defined by the Mozilla Public License, v. 2.0.
  #%]
EOF

};

sub exists {
    my ($self, $file) = @_;

    my $content = read_file($file);
    return
        $content =~ /The contents of this file are subject to/
        || $content =~ /is subject to the terms of the/;
}

sub add {
    my ($self, $file) = @_;

    return if $self->exists($file);

    my ($ext) = $file =~ /^.+\.(.+)$/;
    my $boiler_plate = BOILER_PLATES->{$ext}
        or die "failed to find boiler-plate for .$ext\n";
    my @boiler_plate = split(/\n/, $boiler_plate);
    push @boiler_plate, '';

    my @file = read_file($file);
    if ($file[0] =~ /^#!/) {
        splice(@file, 1, ($file[1] eq "\n" ? 1 : 0), ("\n", @boiler_plate));
    } else {
        splice(@file, 0, 0, @boiler_plate);
    }
    write_file($file, join('', @file));
    message("$file updated");
}

1;
