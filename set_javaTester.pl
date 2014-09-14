use strict;
use warnings;
use feature qw(say);

my $DEBUG = 0;

if ($#ARGV < 0) {
	print "ERROR: no arguments\n";
	say "usage: \"perl set_javaTester.pl ProblemClass.java\"";
	exit(1);
}

my $file_name = $ARGV[0];
print "Target file name: $file_name\n";

open(IN, $file_name) || die "Error: File $file_name not found";
my @buf = <IN>;
close(IN);

my ($class, $method, $parameters, $returns, $method_signature) = ("", "", "", "", "");
my ($IS_EXAMPLES, $IS_TEST_DATA, $IS_PROBLEM_STATEMENT) = (0, 0, 0);
my $test_case = -1;
my @test_param_data;
my @ans_data;
my @problem_statement;
foreach $b(@buf) {
	if ($b =~ /PROBLEM STATEMENT/) {
		$IS_PROBLEM_STATEMENT = 1;
	}
	if ($IS_PROBLEM_STATEMENT == 1) {
		if ($b =~ /\*\//) {
			$IS_PROBLEM_STATEMENT = 0;
		} elsif ($b =~ /^(.*)$/) {
			push(@problem_statement, $1);
		}
	}

	if ($b =~ /^EXAMPLES$/) {
		$IS_EXAMPLES = 1;
	}
	if ($IS_EXAMPLES == 1) {
		if ($b =~ /^(\d+)\)$/) {
			$test_case = $1;
			$IS_TEST_DATA = 1;

			my @empty = ();
			push(@test_param_data, \@empty);
			next;
		}

		if ($IS_TEST_DATA) {
			if ($b =~ /^Returns: (\w+)$/) {
				push(@ans_data, $1);
				$IS_TEST_DATA = 0;
			} elsif ($b =~ /^(.+)$/) {
				push($test_param_data[$test_case], $1);
			}
		}
	}

	if ($b =~ /^Class:(\w+)$/) {
		$class = $1;
	}
	if ($b =~ /^Method:(\w+)$/) {
		$method = $1;
	}
	if ($b =~ /^Parameters:(.+)$/) {
		$parameters = $1;
	}
	if ($b =~ /^Returns:(\w+)$/) {
		$returns = $1;
	}
	if ($b =~ /^Method signature:(.+)$/) {
		$method_signature = $1;
	}
}

# for debug
# change output file name on this line
if ($DEBUG == 1) {
	$class = join("", $class, "Test");
}


### Create code
open(my $out, "> ${class}.java") || die "Error: Cannot open $file_name to write";

# problem statement
write_code($out, 0, "/*");
foreach $b(@problem_statement) {
	write_code($out, 0, $b);
}
write_code($out, 0, "*/");

# problem method
write_code($out, 0, "import java.util.*;");
write_code($out, 0, "");
write_code($out, 0, "class ${class} {");
write_code($out, 1, "");
write_code($out, 1, "public $method_signature {");
write_code($out, 2, "return 1;");
write_code($out, 1, "}");

write_code($out, 1, "// BEGIN CUT HERE");
# main method
write_code($out, 1, "public static void main(String[] args) {");
write_code($out, 2, "");
write_code($out, 2,	"${class} ___test = new ${class}();");
write_code($out, 2, "___test.run_test(-1);");
write_code($out, 1, "}");
write_code($out, 1, "");

# public void run_test
my $test_count = @test_param_data;
write_code($out, 1, "public void run_test(int Case) {");
for (my $i = 0; $i < $test_count; $i++) {
	write_code($out, 2, "if ((Case == -1) || (Case == ${i})) test_case_${i}();");
}
write_code($out, 1, "}");

# private void verify_case
write_code($out, 1, "private void verify_case(int Case, int Expected, int Received) {");
write_code($out, 2,	"System.out.print(\"Test Case #\" + Case + \"...\");");
write_code($out, 2, "if (Expected == Received)");
write_code($out, 3, "System.out.println(\"PASSED\");");
write_code($out, 2,	"else {");
write_code($out, 3, "System.out.println(\"FAILED\");");
write_code($out, 3, "System.out.println(\"Expected: \\\"\" + Expected + \"\\\"\");");
write_code($out, 3, "System.out.println(\"Expected: \\\"\" + Received + \"\\\"\");");
write_code($out, 2, "}");
write_code($out, 1, "}");

# private void test_case_0 ~
for (my $i = 0; $i < $test_count; $i++) {
	write_code($out, 1, "private void test_case_${i}() {");

	my $param_count = scalar(@{$test_param_data[$i]});
	for (my $j = 0; $j < $param_count; $j++) {
		my $val = $test_param_data[$i][$j];
		if ($val =~ /^\d/) {
			write_code($out, 2,	"int Arg${j} = ${val};");
		} elsif ($val =~ /^{\d/) {
			write_code($out, 2, "int Arg${j}[] = ${val};");
		}
	}

	if ($ans_data[$i] =~ /^\d/) {
		write_code($out, 2, "int Arg${param_count} = ${ans_data[$i]};");
	} elsif ($ans_data[$i] =~ /^{\d/) {
		write_code($out, 2, "int Arg${param_count}[] = ${ans_data[$i]};");
	}

	my $method_val = "${method}(";
	for (my $j = 0; $j < $param_count; $j++) {
		$method_val = join("", $method_val, "Arg${j}");
		if ($j == $param_count-1) {
			$method_val = join("", $method_val, ")");
		} else {
			$method_val = join("", $method_val, ", ");
		}
	}
	write_code($out, 2, "verify_case(${i}, Arg${param_count}, ${method_val});");
	write_code($out, 1, "}");
}

write_code($out, 1, "// END CUT HERE");
write_code($out, 0, "};");
close $out;

### sub routines
sub write_code {
	my ($out, $tab, $code) = @_;
	for (my $i = 0; $i < $tab; $i++) {
		print $out "\t";
	}
	say $out $code;
}
