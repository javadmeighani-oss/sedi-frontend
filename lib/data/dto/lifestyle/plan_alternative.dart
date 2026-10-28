/// One alternative item Sedi's rules would accept for a plan slot (`GET /lifestyle/actions/{id}/alternatives`).
class PlanAlternative {
  final String itemId;
  final String title;
  final String detail;

  const PlanAlternative({required this.itemId, required this.title, this.detail = ''});
}
