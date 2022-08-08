#/usr/bin/env bash

OUTPUT_DIRECTORY="$1/$3"

OUTPUT_CLASS="$(tr '[:lower:]' '[:upper:]' <<<"${3:0:1}")${3:1}"
OUTPUT_CLASS="Generated${OUTPUT_CLASS}"

cat <<EOF > $OUTPUT_DIRECTORY/generated.hpp
#pragma once

namespace fly {

class ${OUTPUT_CLASS}
{
public:
    ${OUTPUT_CLASS}(int value);
    int operator()() const;

private:
    const int m_value;
};

} // namespace fly
EOF

cat <<EOF > $OUTPUT_DIRECTORY/generated.cpp
#include "$3/generated.hpp"

namespace fly {

${OUTPUT_CLASS}::${OUTPUT_CLASS}(int value) : m_value(value)
{
}

int ${OUTPUT_CLASS}::operator()() const
{
    return m_value;
}

} // namespace fly
EOF
