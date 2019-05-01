<%!
    import re
    import pdoc
    from pdoc.html_helpers import to_markdown

    def link(d, fmt='{}'):
        name = fmt.format(d.qualname + ('()' if isinstance(d, pdoc.Function) else ''))
        if isinstance(d, pdoc.External):
            return name
        return '[{}](#{})'.format(name, d.refname)

    def _to_md(text, module):
        text = to_markdown(text, module=module, link=link)
        # Setext H2 headings to atx H2 headings
        text = re.sub(r'\n(.+)\n-{3,}\n', r'\n## \1\n\n', text)
        # Convert admonitions into simpler paragraphs, dedent contents
        text = re.sub(r'^(?P<indent>( *))!!! \w+ \"([^\"]*)\"(.*(?:\n(?P=indent) +.*)*)',
                      lambda m: '{}**{}:** {}'.format(m.group(2), m.group(3),
                                                      re.sub('\n {,4}', '\n', m.group(4))),
                      text, flags=re.MULTILINE)
        return text

    def subh(text, level=2):
        # Deepen heading levels so H2 becomes H4 etc.
        return re.sub(r'\n(#+) +(.+)\n', r'\n%s\1 \2\n' % ('#' * level), text)
%>

<%def name="title(level, string, id=None)">
    <% id = ' {#%s}' % id if id is not None else '' %>
${('#' * level) + ' ' + string + id}
</%def>

<%def name="funcdef(f)">
    <%
        returns = show_type_annotations and f.return_annotation() or ''
        if returns:
            returns = ' -> ' + returns
    %>
> `${f.funcdef()} ${f.name}(${', '.join(f.params(annotate=show_type_annotations))})${returns}`
</%def>

<%def name="classdef(c)">
> `class ${c.name}(${', '.join(c.params(annotate=show_type_annotations))})`
</%def>

---
description: |
    API documentation for modules: ${', '.join(m.name for m in modules)}.

lang: en

classoption: oneside
geometry: margin=1in
papersize: a4

linkcolor: blue
links-as-notes: true
...
% for module in modules:
<%
    submodules = module.submodules()
    variables = module.variables()
    functions = module.functions()
    classes = module.classes()

    def to_md(text):
        return _to_md(text, module)
%>
${title(1, 'Module `%s`' % module.name, module.refname)}
${module.docstring | to_md}

% if submodules:
${title(2, 'Sub-modules')}
    % for m in submodules:
* [${m.name}](#${m.refname})
    % endfor
% endif

% if variables:
${title(2, 'Variables')}
    % for v in variables:
${title(3, 'Variable `%s`' % v.name, v.refname)}
${v.docstring | to_md, subh, subh}
    % endfor
% endif

% if functions:
${title(2, 'Functions')}
    % for f in functions:
${title(3, 'Function `%s`' % f.name, f.refname)}

${funcdef(f)}

${f.docstring | to_md, subh, subh}
    % endfor
% endif

% if classes:
${title(2, 'Classes')}
    % for cls in classes:
${title(3, 'Class `%s`' % cls.name, cls.refname)}

${classdef(cls)}

${cls.docstring | to_md, subh}
<%
    class_vars = cls.class_variables(show_inherited_members, sort=sort_identifiers)
    static_methods = cls.functions(show_inherited_members, sort=sort_identifiers)
    inst_vars = cls.instance_variables(show_inherited_members, sort=sort_identifiers)
    methods = cls.methods(show_inherited_members, sort=sort_identifiers)
    mro = cls.mro()
    subclasses = cls.subclasses()
%>
        % if mro:
${title(4, 'Ancestors (in MRO)')}
            % for c in mro:
* [${c.refname}](#${c.refname})
            % endfor
        % endif

        % if subclasses:
${title(4, 'Descendants')}
            % for c in subclasses:
* [${c.refname}](#${c.refname})
            % endfor
        % endif

        % if class_vars:
${title(4, 'Class variables')}
            % for v in class_vars:
${title(5, 'Variable `%s`' % v.name, v.refname)}
${v.docstring | to_md, subh, subh}
            % endfor
        % endif

        % if inst_vars:
${title(4, 'Instance variables')}
            % for v in inst_vars:
${title(5, 'Variable `%s`' % v.name, v.refname)}
${v.docstring | to_md, subh, subh}
            % endfor
        % endif

        % if static_methods:
${title(4, 'Static methods')}
            % for f in static_methods:
${title(5, '`Method %s`' % f.name, f.refname)}

${funcdef(f)}

${f.docstring | to_md, subh, subh}
            % endfor
        % endif

        % if methods:
${title(4, 'Methods')}
            % for f in methods:
${title(5, 'Method `%s`' % f.name, f.refname)}

${funcdef(f)}

${f.docstring | to_md, subh, subh}
            % endfor
        % endif
    % endfor
% endif

##\## for module in modules:
% endfor

-----
Generated by *pdoc* ${pdoc.__version__} (<https://pdoc3.github.io>).
