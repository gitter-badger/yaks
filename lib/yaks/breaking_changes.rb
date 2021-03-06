module Yaks

# These are displayed in a post-install message when installing the
# gem to aid upgraiding

BreakingChanges = {

'0.5.0' => %q~

Breaking Changes in Yaks 0.5.0
==============================

Yaks now serializes its output, you no longer have to convert to JSON
yourself. Use `skip :serialize' to get the old behavior, or
`json_serializer` to use a different JSON implementation.

The single `after' hook has been replaced with a set of `before',
`after', `around' and `skip' hooks.

If you've created your own subclass of `Yaks::Format' (previously:
`Yaks::Serializer'), then you need to update the call to
`Format.register'.

These are potentially breaking changes. See the CHANGELOG and README
for full documentation.

~,

'0.4.3' => %q~

Breaking Changes in Yaks 0.4.3
==============================

Yaks::Mapper#filter was removed, if you override this method in your
mappers to conditionally filter attributes or associations, you will
have to override #attributes or #associations instead.

When specifying a rel_template, now a single {rel} placeholder is
expected instead of {src} and {dest}.

There are other internal changes. See the CHANGELOG and README for full
documentation.

~
}

BreakingChanges['0.4.4'] = BreakingChanges['0.4.3']

end
