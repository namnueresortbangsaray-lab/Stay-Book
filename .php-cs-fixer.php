<?php
$finder = PhpCsFixer\Finder::create()->in([__DIR__.'/app', __DIR__.'/bootstrap', __DIR__.'/config', __DIR__.'/routes', __DIR__.'/tests'])->append([__DIR__.'/public/index.php', __DIR__.'/bin/console']);
return (new PhpCsFixer\Config())->setRiskyAllowed(true)->setRules(['@PSR12' => true, 'declare_strict_types' => true])->setFinder($finder);
