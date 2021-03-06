package Bz::App::Command::info;
use parent 'Bz::App::Base';
use Bz;

sub abstract {
    return "shows information about the current instance";
}

sub execute {
    my ($self, $opt, $args) = @_;
    my @info;
    my $current = Bz->current;
    if ($current->is_workdir) {
        push @info, [ 'subdir',     coloured($current->dir, 'green') ];
        push @info, [ 'summary',    coloured($current->summary || '-', 'green') ];
        push @info, [ 'bug',        'https://bugzilla.mozilla.org/show_bug.cgi?id=' . $current->bug_id ] if $current->bug_id;
        push @info, [ 'repo',       $current->repo ];
        push @info, [ 'url',        $current->url ];
        push @info, [ 'branch',     $current->branch ];
        push @info, [ 'database',   $current->db ];
    } else {
        push @info, [ 'dir',        coloured($current->dir, 'green') ];
        push @info, [ 'url',        $current->url ];
        push @info, [ 'branch',     $current->branch ];
    }

    my $template = '';
    my @values;
    foreach my $ra (@info) {
        $template .= "%8s: %s\n";
        push @values, @$ra;
    }
    printf $template, @values;
}

1;
