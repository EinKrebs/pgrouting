/*PGR-GNU*****************************************************************
File: edwardMoore_driver.cpp

Generated with Template by:
Copyright (c) 2019 pgRouting developers
Mail: project@pgrouting.org

Function's developer:
Copyright (c) 2019 Gudesa Venkata Sai Akhil
Mail: gvs.akhil1997@gmail.com


------

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

********************************************************************PGR-GNU*/

#include "drivers/bellman_ford/edwardMoore_driver.h"

#include <sstream>
#include <deque>
#include <vector>
#include <algorithm>
#include <string>
#include <map>
#include <set>

#include "bellman_ford/pgr_edwardMoore.hpp"

#include "cpp_common/combinations.hpp"
#include "cpp_common/pgdata_getters.hpp"
#include "cpp_common/basePath_SSEC.hpp"
#include "cpp_common/pgr_base_graph.hpp"
#include "cpp_common/pgr_alloc.hpp"
#include "cpp_common/pgr_assert.hpp"

#include "c_types/ii_t_rt.h"

namespace {

#if 0
template < class G >
std::deque< pgrouting::Path >
pgr_edwardMoore(
        G &graph,
        std::vector <II_t_rt> &combinations,
        std::vector < int64_t > sources,
        std::vector < int64_t > targets) {
    std::sort(sources.begin(), sources.end());
    sources.erase(
            std::unique(sources.begin(), sources.end()),
            sources.end());

    std::sort(targets.begin(), targets.end());
    targets.erase(
            std::unique(targets.begin(), targets.end()),
            targets.end());

    pgrouting::functions::Pgr_edwardMoore< G > fn_edwardMoore;
    auto paths = combinations.empty() ?
            fn_edwardMoore.edwardMoore(graph, sources, targets)
            : fn_edwardMoore.edwardMoore(graph, combinations);

    return paths;
}
#endif

template <class G>
std::deque<pgrouting::Path>
edwardMoore(
        G &graph,
        const std::map<int64_t, std::set<int64_t>> &combinations) {
    pgrouting::functions::Pgr_edwardMoore<G> fn_edwardMoore;
    return fn_edwardMoore.edwardMoore(graph, combinations);
}

}  // namespace

void
pgr_do_edwardMoore(
        char *edges_sql,
        char *combinations_sql,
        ArrayType *starts,
        ArrayType *ends,

        bool directed,

        Path_rt **return_tuples,
        size_t *return_count,
        char ** log_msg,
        char ** notice_msg,
        char ** err_msg) {
    using pgrouting::Path;
    using pgrouting::pgr_alloc;
    using pgrouting::pgr_msg;
    using pgrouting::pgr_free;
    using pgrouting::utilities::get_combinations;
    using pgrouting::pgget::get_edges;

    std::ostringstream log;
    std::ostringstream err;
    std::ostringstream notice;
    char *hint = nullptr;

    try {
        pgassert(!(*log_msg));
        pgassert(!(*notice_msg));
        pgassert(!(*err_msg));
        pgassert(!(*return_tuples));
        pgassert(*return_count == 0);

        graphType gType = directed? DIRECTED: UNDIRECTED;

        hint = combinations_sql;
        auto combinations = get_combinations(combinations_sql, starts, ends, true);
        hint = nullptr;

        if (combinations.empty() && combinations_sql) {
            *notice_msg = pgr_msg("No (source, target) pairs found");
            *log_msg = pgr_msg(combinations_sql);
            return;
        }

        hint = edges_sql;
        auto edges = get_edges(std::string(edges_sql), true, false);

        if (edges.empty()) {
            *notice_msg = pgr_msg("No edges found");
            *log_msg = hint? pgr_msg(hint) : pgr_msg(log.str().c_str());
            return;
        }
        hint = nullptr;

        std::deque<Path> paths;
        if (directed) {
            pgrouting::DirectedGraph digraph(gType);
            digraph.insert_edges(edges);
            paths = edwardMoore(digraph, combinations);
        } else {
            pgrouting::UndirectedGraph undigraph(gType);
            undigraph.insert_edges(edges);
           paths = edwardMoore(undigraph, combinations);
        }

        size_t count(0);
        count = count_tuples(paths);

        if (count == 0) {
            (*return_tuples) = NULL;
            (*return_count) = 0;
            notice << "No paths found";
            *log_msg = pgr_msg(notice.str().c_str());
            return;
        }

        (*return_tuples) = pgr_alloc(count, (*return_tuples));
        (*return_count) = (collapse_paths(return_tuples, paths));

        *log_msg = log.str().empty()?
            *log_msg :
            pgr_msg(log.str().c_str());
        *notice_msg = notice.str().empty()?
            *notice_msg :
            pgr_msg(notice.str().c_str());
    } catch (AssertFailedException &except) {
        (*return_tuples) = pgr_free(*return_tuples);
        (*return_count) = 0;
        err << except.what();
        *err_msg = pgr_msg(err.str().c_str());
        *log_msg = pgr_msg(log.str().c_str());
    } catch (const std::string &ex) {
        *err_msg = pgr_msg(ex.c_str());
        *log_msg = hint? pgr_msg(hint) : pgr_msg(log.str().c_str());
    } catch (std::exception &except) {
        (*return_tuples) = pgr_free(*return_tuples);
        (*return_count) = 0;
        err << except.what();
        *err_msg = pgr_msg(err.str().c_str());
        *log_msg = pgr_msg(log.str().c_str());
    } catch(...) {
        (*return_tuples) = pgr_free(*return_tuples);
        (*return_count) = 0;
        err << "Caught unknown exception!";
        *err_msg = pgr_msg(err.str().c_str());
        *log_msg = pgr_msg(log.str().c_str());
    }
}
