function result = config_parser(ini_file, target)
I = INI('File',ini_file);
I.read();
Sections = I.get('Sections');
for k = 1:numel(Sections)
    if strcmp(target, Sections{1, k})
        result = I.get(Sections{k});
    end
end
end