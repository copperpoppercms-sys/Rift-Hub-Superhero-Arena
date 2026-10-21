"""Synchronize feature modules into the canonical standalone entry and editable file."""
from pathlib import Path
import html
r=Path(__file__).parent
p=r/'main.lua';s=p.read_text()
for variable,file in [('MakeVisuals','Visuals'),('MakeInstinct','Instinct'),('MakeInterface','Interface'),('MakeSession','SessionTools')]:
 start=s.index('local '+variable+'=(function()')
 end=s.index('\nend)()',start)+len('\nend)()')
 s=s[:start]+'local '+variable+'=(function()\n'+(r/'src'/f'{file}.lua').read_text()+'\nend)()'+s[end:]
p.write_text(s)
p=r/'docs/SuperheroArena_Editor.html';page=p.read_text();a=page.index('<textarea id="source"');a=page.index('>',a)+1;b=page.index('</textarea>',a)
p.write_text(page[:a]+html.escape(s)+page[b:])
print('Updated standalone and full editable script')
