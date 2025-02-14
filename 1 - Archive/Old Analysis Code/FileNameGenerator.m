function [fileName] = FileNameGenerator()
prompt = {'Enter Subject ID' ; 'Protocol (BBB/B)'};
dlgtitle = 'Experiment Information';
dims = [2 60; 2 60];
definput = {'Subject-ID', 'Protocol-1' };
format shortg;
dateTime = clock;
dateTime = fix(dateTime);
dateTime = join(string(dateTime), '-');
userInput = inputdlg(prompt,dlgtitle,dims,definput);
userInput = regexprep(userInput, ' ', '_');
fileName = join(strjoin([join(string(userInput), '-'), dateTime], '-'), '-' );
end
