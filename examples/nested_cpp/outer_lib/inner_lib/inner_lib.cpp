#include "nested_cpp/outer_lib/inner_lib/inner_lib.hpp"

namespace inner {

int outer_value()
{
    return OUTER_VALUE;
}

int inner_value()
{
    return INNER_VALUE;
}

} // namespace inner
