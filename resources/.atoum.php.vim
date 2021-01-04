<?php

use
  \atoum\atoum
;

$stdOutWriter = new atoum\writers\std\out();

$vimReport = new atoum\reports\asynchronous\vim();
$vimReport
  ->addWriter($stdOutWriter)
;

$runner->addReport($vimReport);
