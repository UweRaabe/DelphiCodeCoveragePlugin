# DelphiCodeCoveragePlugin
Delphi Code Coverage Plugin

The DelphiCode Coverage Plugin adds code coverage to teh Delphi IDE. It supports Delphi 10.2 Tokyo, Delphi 10.3 Rio, Delphi 10.4 Sydney and Delphi 11 Alexandria.

To install the plugin open the appropriate package for your Delpih version, compile and install it into the IDE. Due to a display problem of the main toolbar a restart of teh IDE is suggested. After that you should see two code coverage buttons: 

![RunCodeCoverage](https://user-images.githubusercontent.com/9463873/138177527-34b6e174-ccd4-4de2-b3e4-3b4c0f9651fb.png) Run Code Coverage: starts the test project in code coverage mode and displays the results. 

![CodeCoverage](https://user-images.githubusercontent.com/9463873/138177322-9422fa74-9a9d-4138-8bca-29bf4ade604a.png) Switch Code Coverage: enables or disables code coverage for the current method (where the cursor is in).


The plugin is meant for Test Driven Development (TDD) to control which code parts are covered by tests and which are not.

For a demonstration after installing the plugin, open the TestProject from the source folder. It consists of TestedUnit1, which declares a class TTestedClass with two methods to test. TestUnit1 contains the test class for DUnitX. The test class has two tests, each for one method in TTestedClass, and several test cases with different parameters for the tested methods. Initially only the first test case of each test is enabled, the others are commented out.
Now open TestedUnit and place the cursor inside the implementation of TestedMethod1. Click on the Switch Code Coverage button in the toolbar or press Ctrl-Alt-F5. If code coverage for a method is enabled the code coverage symbol appears in the gutter left of the method header. Switching code coverage also works when the cursor is placed inside the method declaration in the class.

![image](https://user-images.githubusercontent.com/9463873/138178387-3a67ca3d-2f23-4c6f-aa1c-0562debf641c.png)


Click the Run Code Coverage toolbar button. The test programm will run and at the end the code coverage will be displayed.

![image](https://user-images.githubusercontent.com/9463873/138178682-f7a4a8e8-5c55-44fc-ac47-c88b330705d9.png)

Right to the method header you can see the code coverage of the method in percent (lines executed vs. total lines). The number in brackets behind each line shows the number of executions of that line. The red arrow after a line shows a line never executed. Little circles in the first column of each code line give a quick overview which lines are executed (filled blue circle), which are not executed (filled red circle) and which cannot be executed (hollow blue circle). The last also have no blue debugger dots in the gutter.

Uncommenting the different test cases will result in more code covered. The goal is to have as much test cases to get 100% code coverage.
