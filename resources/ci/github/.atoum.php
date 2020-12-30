<?php

use
	atoum\atoum\reports
;

$runner
	->addTestsFromDirectory(__DIR__ . '/tests/units/src')
	->disallowUsageOfUndefinedMethodInMock()
;

if (getenv('CI'))
{
	$script->addDefaultReport();

	$coverallsToken = getenv('COVERALLS_REPO_TOKEN');

	if ($coverallsToken)
	{
		$coverallsReport = new reports\asynchronous\coveralls('src', $coverallsToken);

		$defaultFinder = $coverallsReport->getBranchFinder();

		$coverallsReport
			->setBranchFinder(function() use ($defaultFinder) {
					if (($branch = getenv('GITHUB_REF')) === false)
					{
						$branch = $defaultFinder();
					}

					return $branch;
				}
			)
			->setServiceName('Github Action')
			->setServiceJobId(getenv('GITHUB_RUN_NUMBER'))
			->addDefaultWriter()
		;

		$runner->addReport($coverallsReport);
	}
}
