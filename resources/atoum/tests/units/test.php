<?php

namespace eastoriented\tests\units;

use atoum\atoum\mock;

abstract class test extends \atoum\atoum\test
{
	function beforeTestMethod($method)
	{
		mock\controller::disableAutoBindForNewMock();

		$this->mockGenerator
			->allIsInterface()
			->eachInstanceIsUnique()
		;
	}
}
