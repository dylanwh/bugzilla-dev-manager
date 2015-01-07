package Bz::App::Command::patch;
use parent 'Bz::App::Base';
use Bz;

use Bz::Util 'coloured';
use LWP::Simple;
use URI;
use URI::QueryParam;

sub abstract {
    return "downloads and applies a patch";
}

sub usage_desc {
    return "bz patch [bug_id|source_url|file] [--last] [--all] [--download] [--test]";
}

sub opt_spec {
    return (
        [ "last|l",       "apply the last/latest patch without prompting" ],
        [ "all|a",        "list all patches" ],
        [ "download|d",   "download patch, but don't apply" ],
        [ "test|t",       "run tests after applying patch" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    shift @$args if @$args && $args->[0] eq 'bug';
}

sub description {
    return <<EOF;
downloads and applies a patch from the specified bug or source.

if the current instance's directory name is a bug id, that bug will be queried
for attachments.  when executed from a repo the bug_id is required.

you can provide an url to a diff instead of a bug id.
EOF
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $current = Bz->current();
    my $source;
    $source = shift @$args
        if @$args && $args->[0] !~ /^-/;
    $source ||= $current->is_workdir ? $current->bug_id : undef;
    die $self->usage_error('missing bug_id or source') unless $source;

    my $filename;
    my $delete = 1;
    if (-e $source) {
        $filename = $source;
        $delete = 0;

    } elsif ($source =~ m#^https?://#) {
        my $uri = URI->new($source)
            or die "invalid url: $source\n";
        my @segments = $uri->path_segments();
        if (@segments) {
            $filename = pop(@segments);
        } else {
            $filename = $uri->host;
        }
        if ($filename eq 'attachment.cgi') {
            if ($current->is_workdir) {
                $filename = $current->bug_id . '-' . $uri->query_param('id') . '.patch';
            } else {
                $filename = $uri->query_param('id') . '.patch';
            }
        } else {
            $filename ||= 'download.patch';
            $filename .= '.patch' unless $filename =~ /\./;
        }
        message("downloading $uri to $filename");
        getstore($uri, $filename);

    } else {
        my $bug_id = $source;
        message("fetching patches from bug $bug_id");
        my $summary;
        if ($current->is_workdir) {
            $summary = $current->summary if $current->bug_id && $bug_id == $current->bug_id;
        }
        info($summary || Bz->bug($bug_id)->summary);

        my @patches = @{ Bz->bugzilla->attachments($bug_id) };
        if (!$opt->all) {
            @patches = grep { $_->{is_patch} && !$_->{is_obsolete} } @patches;
        }
        die "no patches found\n" unless @patches;
        die "too many patches found\n" if scalar(@patches) > 10;

        my $prompt = "  0. cancel\n";
        my @options = ('0');
        for(my $i = 1; $i <= scalar @patches; $i++) {
            my $patch = $patches[$i - 1];
            $prompt .= sprintf(
                " %2s. %s %s\n",
                $i,
                $patch->{summary},
                ($opt->all && $patch->{is_obsolete} ? '[obsolete]' : ''),
            );
            push @options, $i;
        }
        $prompt .= '? ';
        my $num;
        if ($opt->last) {
            $num = $options[$#options];
            print coloured($prompt, 'yellow') . "$num\n";
        } else {
            $num = prompt($prompt, join('', @options));
        }
        exit unless $num;
        my $attach_id = $patches[$num - 1]->{id};

        if (!$opt->download) {
            info("patching " . $current->dir . " with #$attach_id");
        }
        $filename = $current->download_patch($attach_id);
    }

    if (!$opt->download) {
        $current->apply_patch($filename);
        if (!$current->is_workdir && $delete) {
            info("deleting $filename");
            unlink($filename);
        } elsif ($opt->test) {
            info("running tests");
            $current->test();
        }
    }
}

1;
