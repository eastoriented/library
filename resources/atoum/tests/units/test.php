<?php

namespace eastoriented\tests\units;

use atoum\mock;

abstract class test extends \atoum
{
	function beforeTestMethod($method)
	{
		mock\controller::disableAutoBindForNewMock();

		$this->mockGenerator
			->allIsInterface()
			->eachInstanceIsUnique()
		;

		return parent::beforeTestMethod($method);
	}
}
