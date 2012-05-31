//! reformats an XML tree with TEXT elements so that when rendered with @[Parser.XML.Tree.Node.render_xml()]
//! the result is more palatable to human readers.
//!
//! @note
//! this method will alter the tree you pass in by adding TEXT elements.
object indent_tree(object parent, void|int indent_text, void|int level)
{
    int subnodes = false;
    foreach(parent->get_children();; object child)
    {
        if (child->get_node_type() == Parser.XML.Tree.XML_ELEMENT ||
            (child->get_node_type() == Parser.XML.Tree.XML_TEXT && indent_text))
        {
            subnodes = true;
            parent->add_child_before(Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_TEXT, "", ([]), "\r\n"+"    "*level), child);
            indent_tree(child, indent_text, level+1);
        }
    }
    if (subnodes && level)
        parent->add_child(Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_TEXT, "", ([]), "\r\n"+"    "*(level-1)));
    return parent;
}

