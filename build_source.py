"""Build the standalone loader by embedding src/extensions.luau into source.luau."""
from pathlib import Path

root = Path(__file__).resolve().parent
source_path = root / 'src' / 'source.luau'
source = source_path.read_text(encoding='utf-8')
marker = '-- BEGIN FATALITY EXTENSIONS\n'
if marker in source:
    source = source[:source.index(marker)]
else:
    assert source.endswith('return Fatality;\n') or source.endswith('return Fatality;')
    source = source[:source.rindex('return Fatality;')]
    source = source.replace('\t\treturn MenuLib;', '''\t\tMenuLib.Root, MenuLib.Button, MenuLib.State = MenuLiber, MenuButton, _B;
\t\tMenuLib.Columns = {Left, Center, Right};
\t\treturn MenuLib;''', 1)
    source = source.replace('ReloadConfig = function()', 'Open = function() ElementToggle(true); end,\n\t\tClose = function() ElementToggle(false); end,\n\t\tReloadConfig = function()', 1)
    source = source.replace('local IsSame = ValueFrame.BackgroundColor3 == rgb or ValueFrame.BackgroundTransparency == opc;',
        'local IsSame = ValueFrame.BackgroundColor3 == rgb and ValueFrame.BackgroundTransparency == opc;', 1)
    source = source.replace('''\t\t\t\tif TAB_WARP then
\t\t\t\t\tfor i,v in next , Fatal.Menus do''', '''\t\t\t\tif TAB_WARP and TAB_WARP.Activate then
\t\t\t\t\tTAB_WARP.Activate();
\t\t\t\telseif TAB_WARP then
\t\t\t\t\tfor i,v in next , Fatal.Menus do''', 1)
    source = source.replace('export type Menu = {', '''export type BindConfig = {
    Key: (string | Enum.KeyCode)?,
    Mode: string?,
    Visible: boolean?,
}

export type Tab = {
    Name: string,
    Icon: string?,
    Position: string?,
    TabsPosition: string?,
    AutoFill: boolean?,
}

export type Menu = {''', 1)
    source = source.replace('\tAutoFill: boolean\n}', '\tAutoFill: boolean,\n\tTabsPosition: string?,\n}', 1)
    for name in ('Toggle', 'Button'):
        anchor = 'export type ' + name + ' = {\n'
        source = source.replace(anchor, anchor + '\tBindable: boolean?,\n\tBindId: string?,\n\tBind: BindConfig?,\n', 1)

extension = (root / 'src' / 'extensions.luau').read_text(encoding='utf-8')
assert extension.endswith('return install\n')
extension = extension[:extension.rindex('return install')]
source += marker + 'do\n' + extension + '\ninstall(Fatality, UserInputService, RunService)\nend\n-- END FATALITY EXTENSIONS\n\nreturn Fatality;\n'
source_path.write_text(source, encoding='utf-8', newline='\n')
print('Built src/source.luau')
