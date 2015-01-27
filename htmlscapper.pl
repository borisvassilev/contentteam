:- module(content, [ write_to_file/2,scrape/2]).
/**<module> Defines the API for the content team to extract data of
 * classes for the shell. The list of predicates are listed here.
 *
 * List predicates.
 *
 */
:- use_module(library(http/http_client)).
:- use_module(library(http/http_sgml_plugin)).
:- use_module(library(http/http_open)).
:- use_module(library(xpath)).

write_to_file(Courses, File) :-
	setup_call_cleanup(open(File, write, Out),
	    forall(member(Course, Courses), format(Out, "course ~q.~n", Course)),
	    close(Out)).

%%	run_online_query(+Contents:html)// is det
%
%
/*url_scrapper(URL, Result) :-
	http_get(URL, DomReply, []),
	findall(Course, xpath(DomReply, //p(@class='course-name'), Course), HCourse),
	findall(Course, course_name(HCourse, Course),Result),
	write_to_file(Result,"t.db"),
	true.

course_name(HtmlCourse, Course) :-
	select(element(_,_,[Course]), HtmlCourse, _).
*/


scrape(URL, Data) :-
    http_open(URL, In, []),
    load_html(In, DOM, [syntax_errors(quiet)]),
    close(In),
    courses(DOM, Data),
    write_to_file(Data,"t.db").

courses(DOM, Courses) :-
    findall(CN_D, cn_d(DOM, CN_D), CNs_Ds),
    list_to_pairs(CNs_Ds, Courses).

cn_d(DOM, CN_D) :-
    xpath(DOM, //p, P), % select a <p>
    once(cn_d_1(P, CN_D)). % succeed only once!

cn_d_1(P, Name) :- % selects class='course-name'
    cn_d_2(P, 'course-name', Codes),
    phrase(course_name(Name), Codes).
cn_d_1(P, description(Rest)) :- % class='course-descriptions'
    cn_d_2(P, 'course-descriptions', Codes),
    dif(Codes, []),
    phrase(course_descriptions(description(Rest)), Codes, Rest).

cn_d_2(P, Class, Codes) :-
    xpath(P, /self(@class=Class, normalize_space), Text),
    atom_codes(Text, Codes).

list_to_pairs([], []).
list_to_pairs([A,B|Rest], [A-B|Pairs]) :-
    list_to_pairs(Rest, Pairs).

:- use_module(library(dcg/basics)).

course_descriptions(description(_)) --> [].

course_name(name(M, N, T, U)) -->
    % nonblanks followed by a single white space is the "CSE"
    nonblanks(M_codes), white,
    % everything up to a dot, and the dot, and a white space is the number
    string_without(`.`, N_codes), `.`, white,
    % Everything up to a space...
    string(T_codes), white,
    % ... followed by something enclosed in "(" and ")", and at the
    % very end of the whole list
    `(`, string(U_codes),`)`,
    % convert everything to atoms
    {   atom_codes(M, M_codes),
        atom_codes(N, N_codes),
        atom_codes(T, T_codes),
        atom_codes(U, U_codes)
    }.
